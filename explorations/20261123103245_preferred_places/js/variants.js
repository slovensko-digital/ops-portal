import { Controller } from "./stimulus.js"
import Base from "./base_controller.js"

// 0 — today's behaviour: summary in the placeholder, "a ďalšie" after two items.
export class CurrentController extends Base {
  // Production keeps the typed query when the list closes.
  resetQuery() {}

  selectionChanged() {
    const names = this.checked.map(cb => cb.dataset.fullLabel)
    if (names.length === 0) this.inputTarget.placeholder = "Vyhľadajte lokality..."
    else if (names.length <= 2) this.inputTarget.placeholder = names.join(", ")
    else this.inputTarget.placeholder = `${names.slice(0, 2).join(", ")} a ďalšie`
  }
}

// A + B — removable chips. A renders them above the search field, B inside the bordered box.
export class ChipsController extends Base {
  static targets = [...Base.targets, "chips", "count"]

  selectionChanged() {
    const items = this.selection
    this.chipsTarget.innerHTML = items.map(item => this.chip(item)).join("")
    this.chipsTarget.classList.toggle("is-empty", items.length === 0)
    if (this.hasCountTarget) this.countTarget.textContent = items.length ? `(${items.length})` : ""
    this.inputTarget.placeholder = items.length ? "Pridať ďalšie..." : "Vyhľadajte lokality..."
  }

  chip(item) {
    return `
      <span class="place-chip">
        <span class="place-chip-label">${this.chipLabel(item)}</span>
        ${this.removeButton(item)}
      </span>`
  }

  // B: clicking the box anywhere focuses the inline input.
  focusInput(event) {
    if (event.target.closest("button")) return
    this.inputTarget.focus()
  }

  // B: Backspace in an empty input removes the last chip.
  backspace(event) {
    if (event.key !== "Backspace" || this.inputTarget.value !== "") return
    const last = this.selection.at(-1)
    if (last) this.uncheck(last.name, last.value)
  }
}

// A2 — A with the issue-filter pills (search_engine/controls/remove_filters/_remove_filter.html.erb):
// outlined pill, × first, the whole pill removes the place. One plain style for every place,
// "Bratislava - Petržalka" uses the same " - " separator as the dropdown search.
export class PillsController extends ChipsController {
  chip(item) {
    return `
      <button type="button" class="button button-transparent filter-select-button"
        title="${this.pillTitle(item)}" aria-label="Odstrániť ${this.esc(item.fullLabel)}"
        data-action="${this.identifier}#remove" data-name="${item.name}" data-value="${item.value}">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 14 20" aria-hidden="true"><polygon points="14 4.06 12.94 3 7 8.94 1.06 3 0 4.06 5.94 10 0 15.94 1.06 17 7 11.06 12.94 17 14 15.94 8.06 10 14 4.06"/></svg>
        <span>${this.pillLabel(item)}</span>
      </button>`
  }

  pillLabel(item) {
    return this.esc(item.fullLabel)
  }

  pillTitle() {
    return "Odstrániť"
  }
}

// A3 — A2, but a district shows its municipality greyed out instead of the " - " separator.
// Same weight for everything; only the colour tells municipality and district apart.
export class PillsMutedController extends PillsController {
  pillLabel(item) {
    if (!item.district) return this.esc(item.municipality)
    return `<span class="place-muni">${this.esc(item.municipality)}</span> ${this.esc(item.district)}`
  }
}

// A4 — A2 pills, a district shows only its own name ("Petržalka"). The municipality stays in the
// tooltip and the aria-label, because district names repeat (Bratislava / Košice - Staré Mesto).
export class PillsDistrictController extends PillsController {
  pillLabel(item) {
    return this.esc(item.district || item.municipality)
  }

  pillTitle(item) {
    return `Odstrániť: ${this.esc(item.fullLabel)}`
  }
}

// C — multi-row list under the field, districts grouped under their municipality
// (uniform mode: one flat row per place).
export class ListController extends Base {
  static targets = [...Base.targets, "selected", "summary"]

  selectionChanged() {
    const items = this.selection
    const groups = Map.groupBy(items, i => i.municipality)

    this.summaryTarget.innerHTML = items.length
      ? `Sledujete <strong>${this.lokalit(items.length)}</strong>`
      : "Zatiaľ nesledujete žiadnu lokalitu."
    this.summaryTarget.nextElementSibling.classList.toggle("none", items.length === 0)

    if (this.uniform) {
      this.selectedTarget.innerHTML = items.map(i => `
        <li class="place-row place-row--flat">
          <span class="place-row-name">${this.dashed(i)}</span>
          ${this.removeButton(i)}
        </li>`).join("")
      return
    }

    this.selectedTarget.innerHTML = [...groups].map(([municipality, rows]) => {
      const whole = rows.find(r => !r.district)
      const districts = rows.filter(r => r.district)
      return `
        <li class="place-row ${whole ? "" : "place-row--group"}">
          <span class="place-row-name">${this.esc(municipality)}${whole ? "" : ` <span class="place-row-hint">mestské časti</span>`}</span>
          ${whole ? this.removeButton(whole) : ""}
        </li>
        ${districts.map(d => `
          <li class="place-row place-row--district">
            <span class="place-row-name">${this.esc(d.district)}</span>
            ${this.removeButton(d)}
          </li>`).join("")}`
    }).join("")
  }
}

// D — closed: full selection as wrapping multi-row text. Open: search + "Vybrané" pinned on top of the dropdown.
export class SummaryController extends Base {
  static targets = [...Base.targets, "summary", "pinned", "editor"]

  open() {
    super.open()
    this.editorTarget.classList.remove("none")
    this.summaryTarget.classList.add("none")
  }

  edit() {
    this.open()
    this.inputTarget.focus()
  }

  close(event) {
    if (!this.element.classList.contains("is-open")) return
    if (event && this.clickedInside(event.target)) return
    super.close()
    this.editorTarget.classList.add("none")
    this.summaryTarget.classList.remove("none")
    this.selectionChanged()
  }

  escape() {
    this.close()
    this.summaryTarget.focus()
  }

  selectionChanged() {
    const items = this.selection

    this.summaryTarget.querySelector(".place-summary-text").innerHTML = items.length
      ? items.map(i => `<span class="place-summary-item">${this.esc(i.fullLabel)}</span>`).join(", ")
      : `<span class="place-summary-empty">Vyhľadajte lokality...</span>`

    this.pinnedTarget.innerHTML = items.length ? `
      <li class="place-section">Vybrané (${items.length})
        <button type="button" class="place-link" data-action="${this.identifier}#clearAll">Zrušiť všetky</button>
      </li>
      ${items.map(i => `
        <li class="check-box active place-pinned">
          <label data-action="click->${this.identifier}#unpin" data-name="${i.name}" data-value="${i.value}">
            <div class="form-check-box"><svg viewBox="0 0 16 20"><polygon points="5.51 15.78 0 10.26 1.06 9.2 5.51 13.66 14.94 4.22 16 5.28 5.51 15.78"/></svg></div>
            <span>${this.esc(i.fullLabel)}</span>
          </label>
        </li>`).join("")}
      <li class="place-section">Všetky lokality</li>` : ""
  }

  unpin(event) {
    event.preventDefault()
    const { name, value } = event.currentTarget.dataset
    this.uncheck(name, value)
  }
}


// Prototype-only: top-bar switch for the uniform look, remembered across pages.
export class ProtoToggleController extends Controller {
  connect() {
    this.element.checked = document.documentElement.classList.contains("uniform-places")
  }
  change() {
    localStorage.setItem("uniform-places", this.element.checked ? "1" : "")
    document.documentElement.classList.toggle("uniform-places", this.element.checked)
    window.dispatchEvent(new Event("proto:uniform"))
  }
}

// Prototype-only: show what the form would POST instead of submitting.
export class PayloadController extends Controller {
  static targets = ["output"]
  show(event) {
    event.preventDefault()
    const data = new FormData(this.element)
    const lines = [...data.entries()].map(([k, v]) => `${k} = ${JSON.stringify(v)}`)
    this.outputTarget.textContent = lines.join("\n")
    this.outputTarget.classList.remove("none")
  }
}
