import { Controller } from "./stimulus.js"

// Behaviour shared by every variant; same as app/javascript/controllers/preferred_places_controller.js
// minus the placeholder summary. Variants override selectionChanged().
export default class extends Controller {
  static targets = ["input", "list", "checkbox", "item", "empty"]

  connect() {
    this.rerender = () => this.selectionChanged()
    window.addEventListener("proto:uniform", this.rerender)
    this.selectionChanged()
  }

  disconnect() {
    window.removeEventListener("proto:uniform", this.rerender)
  }

  // Prototype switch: render municipalities and districts the same way ("Bratislava – Petržalka", "Košice").
  get uniform() {
    return document.documentElement.classList.contains("uniform-places")
  }

  dashed(item) {
    return this.esc(item.fullLabel.replace(" - ", " – "))
  }

  open() {
    this.listTarget.classList.remove("none")
    this.element.classList.add("is-open")
  }

  close(event) {
    if (event && this.clickedInside(event.target)) return
    this.listTarget.classList.add("none")
    this.element.classList.remove("is-open")
    this.resetQuery()
  }

  // Leaving the field discards the unfinished search, so the next open starts with the full list.
  resetQuery() {
    this.inputTarget.value = ""
    this.itemTargets.forEach(item => item.classList.remove("none"))
    this.updateEmpty()
  }

  // Only the search input and what hangs under it keep the list open (as in production, where the
  // controller sits on .autocomplete-wrapper). Label, pills and the gaps between them count as outside.
  // A removed pill/chip is detached by the re-render, so that click is ignored and leaves the list as it was.
  clickedInside(target) {
    if (!target.isConnected) return true
    const parts = [this.inputTarget, this.listTarget, ...(this.hasEmptyTarget ? [this.emptyTarget] : [])]
    return parts.some(part => part.contains(target)) || !!target.closest("[data-keep-open]")
  }

  escape() {
    this.close()
    this.inputTarget.blur()
  }

  enter(event) {
    event.preventDefault()
  }

  filter() {
    const query = this.normalize(this.inputTarget.value.trim())
    this.open()

    if (query === "") {
      this.itemTargets.forEach(item => item.classList.remove("none"))
      this.updateEmpty()
      return
    }

    let municipalityItem = null
    let municipalityMatch = false

    this.itemTargets.forEach(item => {
      const checkbox = item.querySelector("input[type=checkbox]")
      const normalized = this.normalize(checkbox.dataset.fullLabel)

      if (checkbox.dataset.district !== "true") {
        municipalityItem = item
        municipalityMatch = normalized.includes(query)
        item.classList.toggle("none", !municipalityMatch)
      } else {
        const districtMatch = normalized.includes(query)
        item.classList.toggle("none", !(districtMatch || municipalityMatch))
        if (districtMatch && municipalityItem) municipalityItem.classList.remove("none")
      }
    })
    this.updateEmpty()
  }

  // "Not found" state: replaces the (otherwise blank) dropdown while the list is open and nothing matches.
  // Only for variants whose markup has an empty target.
  updateEmpty() {
    if (!this.hasEmptyTarget) return
    const query = this.inputTarget.value.trim()
    const open = this.element.classList.contains("is-open")
    const noMatch = query !== "" && this.itemTargets.every(item => item.classList.contains("none"))

    this.listTarget.classList.toggle("is-no-match", noMatch)
    this.emptyTarget.classList.toggle("none", !(open && noMatch))
    if (noMatch) {
      this.emptyTarget.innerHTML =
        `Pre „<strong>${this.esc(query)}</strong>“ sme nenašli žiadnu obec ani mestskú časť.` +
        `<span>Skontrolujte, či je názov napísaný správne.</span>`
    }
  }

  toggle(event) {
    event.target.closest("li")?.classList.toggle("active", event.target.checked)
    this.selectionChanged()
  }

  // Unchecks the checkbox referenced by a remove button's data-name / data-value.
  remove(event) {
    event.preventDefault()
    event.stopPropagation()
    const { name, value } = event.currentTarget.dataset
    this.uncheck(name, value)
  }

  uncheck(name, value) {
    const checkbox = this.checkboxTargets.find(cb => cb.name === name && cb.value === value)
    if (!checkbox) return
    checkbox.checked = false
    checkbox.dispatchEvent(new Event("change", { bubbles: true }))
  }

  clearAll(event) {
    event?.preventDefault()
    this.checked.forEach(cb => {
      cb.checked = false
      cb.closest("li")?.classList.remove("active")
    })
    this.selectionChanged()
  }

  get checked() {
    return this.checkboxTargets.filter(cb => cb.checked)
  }

  // [{ municipality, district|null, name, value, fullLabel }]
  get selection() {
    return this.checked.map(cb => ({
      municipality: cb.dataset.municipality,
      district: cb.dataset.district === "true" ? cb.dataset.label : null,
      fullLabel: cb.dataset.fullLabel,
      name: cb.name,
      value: cb.value,
    }))
  }

  selectionChanged() {}

  normalize(str) {
    return (str || "")
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "")
      .replace(/[^a-z0-9]/gi, "")
      .toLowerCase()
  }

  esc(s) {
    return s.replace(/[&<>"]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])
  }

  removeButton(item, extraClass = "") {
    return `<button type="button" class="place-remove ${extraClass}"
      aria-label="Odstrániť ${this.esc(item.fullLabel)}" title="Odstrániť"
      data-action="${this.identifier}#remove" data-name="${item.name}" data-value="${item.value}">
      <svg viewBox="0 0 12 12" aria-hidden="true"><path d="M1 1l10 10M11 1L1 11" stroke-width="1.6" fill="none"/></svg>
    </button>`
  }

  // Default: "Bratislava – Petržalka" with the municipality de-emphasised, solo municipality bold.
  chipLabel(item) {
    if (this.uniform) return this.dashed(item)
    if (!item.district) return `<strong>${this.esc(item.municipality)}</strong>`
    return `<span class="place-muni">${this.esc(item.municipality)}</span> ${this.esc(item.district)}`
  }

  lokalit(n) {
    if (n === 1) return "1 lokalitu"
    if (n >= 2 && n <= 4) return `${n} lokality`
    return `${n} lokalít`
  }
}
