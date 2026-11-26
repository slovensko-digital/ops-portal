import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const CONCURRENCY = 4
const DIFF_CONTEXT = 3
const AUTO_SNAPSHOT_INTERVAL = 5 * 60 * 1000

// Admin prompt playground: runs the test cases against the edited prompt and the chosen
// model. The edited prompt stays in localStorage until it is reset to the CMS version.
//
// Snapshots: the baseline is the prompt as last saved to or restored from a snapshot. A prompt
// that differs from both the baseline and the CMS version has edits a snapshot does not hold yet.
export default class extends Controller {
  static targets = [
    "prompt", "model", "diff", "changed", "summary", "outcome", "runAll", "resetDialog",
    "snapshotNote", "snapshotDialog", "snapshotLabel", "snapshotDiff", "revertNotice", "restoreButton"
  ]
  static values = { original: String, storageKey: String, latestSnapshot: String, snapshotsUrl: String }

  connect() {
    const stored = this.#stored()
    if (stored.prompt != null) this.promptTarget.value = stored.prompt
    if (stored.model && [...this.modelTarget.options].some(option => option.value === stored.model)) {
      this.modelTarget.value = stored.model
    }
    this.baseline = stored.baseline ?? (this.latestSnapshotValue || this.originalValue)
    this.#updateChanged()
    this.autoSnapshotTimer = setInterval(() => this.autoSnapshot(), AUTO_SNAPSHOT_INTERVAL)
  }

  disconnect() {
    clearInterval(this.autoSnapshotTimer)
  }

  save() {
    const prompt = this.#isChanged() ? this.promptTarget.value : null
    localStorage.setItem(this.storageKeyValue, JSON.stringify({ prompt, model: this.modelTarget.value, baseline: this.baseline }))
    this.#updateChanged()
    this.renderDiff()
  }

  async snapshot(event) {
    const button = event.currentTarget
    const created = await this.#takeSnapshot("manual", this.snapshotNoteTarget.value)
    if (created == null) return

    this.snapshotNoteTarget.value = ""
    this.#flash(button, created ? "✔ Snapshot uložený" : "Rovnaký ako posledný snapshot")
  }

  async autoSnapshot() {
    if (this.#hasUnsavedEdits()) await this.#takeSnapshot("auto")
  }

  async openSnapshot(event) {
    const response = await fetch(event.currentTarget.dataset.url, { headers: { "Accept": "application/json" } })
    if (!response.ok) return

    this.pendingSnapshot = await response.json()
    const same = this.pendingSnapshot.content === this.promptTarget.value
    this.snapshotLabelTarget.textContent = this.pendingSnapshot.label
    this.#renderDiffInto(this.snapshotDiffTarget, this.promptTarget.value, this.pendingSnapshot.content, "Snapshot je rovnaký ako aktuálny prompt.")
    this.revertNoticeTarget.hidden = same || !this.#hasUnsavedEdits()
    this.restoreButtonTarget.disabled = same
    this.snapshotDialogTarget.showModal()
  }

  async restoreSnapshot() {
    const { content } = this.pendingSnapshot
    if (this.#hasUnsavedEdits() && await this.#takeSnapshot("revert") == null) return

    this.snapshotDialogTarget.close()
    this.promptTarget.value = content
    this.baseline = content
    this.save()
  }

  async snapshotAndReset() {
    if (await this.#takeSnapshot("cms_reload") == null) return

    this.confirmReset()
  }

  // Copies the prompt as it is in the box, placeholders included, to paste into the CMS on the forum.
  async copy(event) {
    const button = event.currentTarget
    const label = button.textContent

    try {
      await navigator.clipboard.writeText(this.promptTarget.value)
      button.textContent = "✔ Skopírované"
    } catch {
      this.promptTarget.select()
      button.textContent = "Kopírovanie zlyhalo, prompt je označený"
    }
    setTimeout(() => { button.textContent = label }, 2000)
  }

  // Asks first when the edits would be lost
  reset() {
    if (this.#isChanged()) {
      this.resetDialogTarget.showModal()
    } else {
      this.confirmReset()
    }
  }

  confirmReset() {
    this.resetDialogTarget.close()
    this.promptTarget.value = this.originalValue
    this.save()
  }

  async runOne(event) {
    await this.#run(event.target.closest("[data-run-url]"))
  }

  async runAll() {
    const testCases = [...this.element.querySelectorAll("[data-run-url]")]
    const queue = [...testCases]
    const restore = this.#busy(this.runAllTarget, "Vyhodnocujú sa testy…")
    testCases.forEach(testCase => this.#showRunning(testCase))

    const worker = async () => {
      while (queue.length > 0) await this.#run(queue.shift())
    }
    await Promise.all(Array.from({ length: CONCURRENCY }, worker))

    restore()
  }

  outcomeTargetConnected() {
    this.#updateSummary()
  }

  outcomeTargetDisconnected() {
    this.#updateSummary()
  }

  renderDiff() {
    if (!this.diffTarget.closest("details").open) return

    this.#renderDiffInto(this.diffTarget, this.originalValue, this.promptTarget.value, "Prompt je rovnaký ako v CMS.")
  }

  #renderDiffInto(target, before, after, sameText) {
    target.replaceChildren()
    if (before === after) {
      target.textContent = sameText
      return
    }

    for (const { type, text } of this.#diffLines(before, after)) {
      const line = document.createElement("span")
      line.className = `diff-line diff-${type}`
      line.textContent = { add: "+ ", del: "- ", same: "  ", gap: "" }[type] + text
      target.append(line)
    }
  }

  async #run(testCase) {
    const result = testCase.querySelector("[data-result]")
    const restore = this.#busy(testCase.querySelector("[data-run-button]"), "Vyhodnocuje sa…")
    this.#showRunning(testCase)

    const body = new FormData()
    body.append("prompt", this.promptTarget.value)
    body.append("model", this.modelTarget.value)

    try {
      const response = await fetch(testCase.dataset.runUrl, {
        method: "POST",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content ?? ""
        },
        body
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      Turbo.renderStreamMessage(await response.text())
    } catch (error) {
      result.innerHTML = '<div class="result result-error" data-status="error"><strong class="result-status">✘ Chyba</strong> <span></span></div>'
      result.querySelector("span").textContent = error.message
      this.#updateSummary()
    } finally {
      restore()
    }
  }

  #showRunning(testCase) {
    testCase.querySelector("[data-result]").innerHTML =
      '<div class="result result-running"><span class="spinner" aria-hidden="true"></span> Vyhodnocuje sa…</div>'
  }

  // Disables the button and shows a spinner in it, returns a function that puts it back.
  #busy(button, label) {
    const original = button.innerHTML
    button.disabled = true
    button.innerHTML = '<span class="spinner" aria-hidden="true"></span> '
    button.append(label)
    return () => {
      button.disabled = false
      button.innerHTML = original
    }
  }

  #updateSummary() {
    const total = this.element.querySelectorAll("[data-run-url]").length
    const results = [...this.element.querySelectorAll("[data-result] [data-status]")]
    if (results.length === 0) {
      this.summaryTarget.textContent = ""
      return
    }

    const passed = results.filter(result => result.dataset.status === "pass").length
    const costs = results.map(result => result.dataset.cost).filter(Boolean).map(Number)
    const parts = [`Prešlo ${passed} z ${total}`]
    if (costs.length > 0) {
      const sum = costs.reduce((a, b) => a + b, 0)
      parts.push(`cena ${this.#usd(sum)}`, `≈ ${this.#usd(sum / costs.length * 1000)} za 1 000 podnetov`)
    }
    this.summaryTarget.textContent = parts.join(" · ")
  }

  #usd(amount) {
    return `${new Intl.NumberFormat("sk-SK", { maximumSignificantDigits: 3 }).format(amount)} $`
  }

  // true when a snapshot was created, false when the latest one already holds this prompt,
  // null when it failed
  async #takeSnapshot(reason, note = "") {
    const content = this.promptTarget.value
    const body = new FormData()
    body.append("content", content)
    body.append("reason", reason)
    body.append("note", note)

    try {
      const response = await fetch(this.snapshotsUrlValue, {
        method: "POST",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content ?? ""
        },
        body
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const created = response.status !== 204
      if (created) Turbo.renderStreamMessage(await response.text())
      this.baseline = content
      this.save()
      return created
    } catch (error) {
      console.error("Snapshot failed", error)
      return null
    }
  }

  #hasUnsavedEdits() {
    const prompt = this.promptTarget.value
    return prompt !== this.baseline && prompt !== this.originalValue
  }

  #flash(button, label) {
    const original = button.textContent
    button.textContent = label
    setTimeout(() => { button.textContent = original }, 2000)
  }

  #isChanged() {
    return this.promptTarget.value !== this.originalValue
  }

  #updateChanged() {
    this.changedTarget.hidden = !this.#isChanged()
  }

  #stored() {
    try {
      return JSON.parse(localStorage.getItem(this.storageKeyValue)) || {}
    } catch {
      return {}
    }
  }

  // Line diff from the longest common subsequence, with unchanged runs collapsed to
  // DIFF_CONTEXT lines around each change.
  #diffLines(before, after) {
    const a = before.split("\n")
    const b = after.split("\n")
    const lcs = Array.from({ length: a.length + 1 }, () => new Uint32Array(b.length + 1))
    for (let i = a.length - 1; i >= 0; i--) {
      for (let j = b.length - 1; j >= 0; j--) {
        lcs[i][j] = a[i] === b[j] ? lcs[i + 1][j + 1] + 1 : Math.max(lcs[i + 1][j], lcs[i][j + 1])
      }
    }

    const lines = []
    let i = 0
    let j = 0
    while (i < a.length || j < b.length) {
      if (i < a.length && j < b.length && a[i] === b[j]) {
        lines.push({ type: "same", text: a[i++] }); j++
      } else if (i < a.length && (j >= b.length || lcs[i + 1][j] >= lcs[i][j + 1])) {
        lines.push({ type: "del", text: a[i++] })
      } else {
        lines.push({ type: "add", text: b[j++] })
      }
    }

    const nearChange = lines.map((_, index) =>
      lines.slice(Math.max(0, index - DIFF_CONTEXT), index + DIFF_CONTEXT + 1).some(line => line.type !== "same")
    )
    return lines.reduce((shown, line, index) => {
      if (nearChange[index]) shown.push(line)
      else if (shown.at(-1)?.type !== "gap") shown.push({ type: "gap", text: "…" })
      return shown
    }, [])
  }
}
