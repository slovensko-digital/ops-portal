import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const CONCURRENCY = 4
const DIFF_CONTEXT = 3

// Admin prompt playground: runs the test cases against the edited prompt and the chosen
// model. The edited prompt stays in localStorage until it is reset to the CMS version.
export default class extends Controller {
  static targets = ["prompt", "model", "diff", "changed", "summary", "outcome", "runAll"]
  static values = { original: String, storageKey: String }

  connect() {
    const stored = this.#stored()
    if (stored.prompt != null) this.promptTarget.value = stored.prompt
    if (stored.model && [...this.modelTarget.options].some(option => option.value === stored.model)) {
      this.modelTarget.value = stored.model
    }
    this.#updateChanged()
  }

  save() {
    const prompt = this.#isChanged() ? this.promptTarget.value : null
    localStorage.setItem(this.storageKeyValue, JSON.stringify({ prompt, model: this.modelTarget.value }))
    this.#updateChanged()
    this.renderDiff()
  }

  reset() {
    this.promptTarget.value = this.originalValue
    this.save()
  }

  async runOne(event) {
    await this.#run(event.target.closest("[data-run-url]"))
  }

  async runAll() {
    const queue = [...this.element.querySelectorAll("[data-run-url]")]
    this.runAllTarget.disabled = true

    const worker = async () => {
      while (queue.length > 0) await this.#run(queue.shift())
    }
    await Promise.all(Array.from({ length: CONCURRENCY }, worker))

    this.runAllTarget.disabled = false
  }

  outcomeTargetConnected() {
    this.#updateSummary()
  }

  outcomeTargetDisconnected() {
    this.#updateSummary()
  }

  renderDiff() {
    const details = this.diffTarget.closest("details")
    if (!details.open) return

    this.diffTarget.replaceChildren()
    if (!this.#isChanged()) {
      this.diffTarget.textContent = "Prompt je rovnaký ako v CMS."
      return
    }

    for (const { type, text } of this.#diffLines(this.originalValue, this.promptTarget.value)) {
      const line = document.createElement("span")
      line.className = `diff-line diff-${type}`
      line.textContent = { add: "+ ", del: "- ", same: "  ", gap: "" }[type] + text
      this.diffTarget.append(line)
    }
  }

  async #run(testCase) {
    const result = testCase.querySelector("[data-result]")
    result.innerHTML = '<div class="result">Prebieha…</div>'

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
    }
  }

  #updateSummary() {
    const total = this.element.querySelectorAll("[data-run-url]").length
    const statuses = [...this.element.querySelectorAll("[data-result] [data-status]")].map(el => el.dataset.status)
    if (statuses.length === 0) {
      this.summaryTarget.textContent = ""
      return
    }

    const passed = statuses.filter(status => status === "pass").length
    this.summaryTarget.textContent = `Prešlo ${passed} z ${total}`
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
      } else if (j < b.length && (i >= a.length || lcs[i][j + 1] >= lcs[i + 1][j])) {
        lines.push({ type: "add", text: b[j++] })
      } else {
        lines.push({ type: "del", text: a[i++] })
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
