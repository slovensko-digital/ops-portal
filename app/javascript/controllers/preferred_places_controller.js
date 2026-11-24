import { Controller } from "@hotwired/stimulus"

// Profile "Preferované mestá alebo obce": searchable checkbox list with the selection shown as
// removable pills above the search input. A district pill shows only the district name; the full
// "Municipality - District" name is in its title and aria-label (district names repeat across cities).
export default class extends Controller {
    static targets = [ "input", "list", "checkbox", "item", "pills", "pillTemplate", "count", "empty" ]
    static values = {
        defaultPlaceholder: { type: String, default: "Vyhľadajte lokality..." },
        addPlaceholder: { type: String, default: "Pridať ďalšie..." },
        removeLabel: { type: String, default: "Odstrániť" }
    }

    connect() {
        const municipalityIds = new Set(this.checkboxTargets.map(cb => cb.dataset.municipalityId))
        municipalityIds.forEach(id => {
            const { parent, districts } = this.group(id)
            this.collapseFullGroup(parent, districts)
        })

        this.paint()
        this.renderSelection()
    }

    open() {
        this.listTarget.classList.remove("none")
        this.element.classList.add("is-open")
        this.updateEmpty()
    }

    close() {
        this.listTarget.classList.add("none")
        this.element.classList.remove("is-open")
        this.inputTarget.value = ""
        this.itemTargets.forEach(item => item.classList.remove("none"))
        this.updateEmpty()
    }

    closeOnOutsideClick(event) {
        if (!this.element.classList.contains("is-open")) return
        if (this.clickedInside(event.target)) return

        this.close()
    }

    enter(event) {
        event.preventDefault()
    }

    filter() {
        const query = this.normalizeString(this.inputTarget.value.trim())
        this.open()

        if (query === "") {
            this.itemTargets.forEach(item => item.classList.remove("none"))
            this.updateEmpty()
            return
        }

        let currentMunicipalityItem = null
        let currentMunicipalityMatch = false

        this.itemTargets.forEach(item => {
            const checkbox = item.querySelector('[data-preferred-places-target="checkbox"]')
            const normalized = this.normalizeString(checkbox.dataset.fullLabel.trim())

            if (checkbox.dataset.district !== "true") {
                currentMunicipalityItem = item
                currentMunicipalityMatch = normalized.includes(query)
                item.classList.toggle("none", !currentMunicipalityMatch)
            } else {
                const districtMatch = normalized.includes(query)
                item.classList.toggle("none", !(districtMatch || currentMunicipalityMatch))

                if (districtMatch && currentMunicipalityItem) {
                    currentMunicipalityItem.classList.remove("none")
                }
            }
        })

        this.updateEmpty()
    }

    // The checked inputs are exactly what gets saved: a whole municipality, or some of its districts.
    // - A checked municipality shows all its districts as ticked, but only the municipality is saved.
    // - Unticking one of those districts unchecks the municipality and checks the other districts,
    //   so the municipality becomes partial (shown as "-").
    // - Ticking the last missing district collapses back to the whole municipality.
    toggle(event) {
        const checkbox = event.target
        const { parent, districts } = this.group(checkbox.dataset.municipalityId)

        if (checkbox.dataset.district !== "true") {
            districts.forEach(district => district.checked = false)
        } else if (parent?.checked) {
            parent.checked = false
            districts.forEach(district => district.checked = district !== checkbox)
        } else {
            this.collapseFullGroup(parent, districts)
        }

        this.paint()
        this.renderSelection()
    }

    collapseFullGroup(parent, districts) {
        if (!parent || districts.length === 0) return
        if (!districts.every(district => district.checked)) return

        parent.checked = true
        districts.forEach(district => district.checked = false)
    }

    group(municipalityId) {
        const members = this.checkboxTargets.filter(cb => cb.dataset.municipalityId === municipalityId)

        return {
            parent: members.find(cb => cb.dataset.district !== "true"),
            districts: members.filter(cb => cb.dataset.district === "true")
        }
    }

    paint() {
        this.checkboxTargets.forEach(checkbox => {
            const li = checkbox.closest("li")
            const { parent, districts } = this.group(checkbox.dataset.municipalityId)

            if (checkbox.dataset.district === "true") {
                li.classList.toggle("active", checkbox.checked || Boolean(parent?.checked))
            } else {
                const partial = !checkbox.checked && districts.some(district => district.checked)

                checkbox.indeterminate = partial
                li.classList.toggle("active", checkbox.checked)
                li.classList.toggle("partial", partial)
            }
        })
    }

    remove(event) {
        const checkbox = this.checkboxTargets.find(cb => cb.id === event.currentTarget.dataset.checkboxId)
        if (!checkbox) return

        checkbox.checked = false
        checkbox.dispatchEvent(new Event("change", { bubbles: true }))
    }

    renderSelection() {
        const checked = this.checkboxTargets.filter(cb => cb.checked)

        this.pillsTarget.replaceChildren(...checked.map(cb => this.buildPill(cb)))
        this.pillsTarget.classList.toggle("none", checked.length === 0)
        this.countTarget.textContent = checked.length > 0 ? `(${checked.length})` : ""
        this.inputTarget.placeholder = checked.length > 0 ? this.addPlaceholderValue : this.defaultPlaceholderValue
    }

    buildPill(checkbox) {
        const pill = this.pillTemplateTarget.content.firstElementChild.cloneNode(true)
        const fullLabel = checkbox.dataset.fullLabel

        pill.dataset.checkboxId = checkbox.id
        pill.title = `${this.removeLabelValue}: ${fullLabel}`
        pill.setAttribute("aria-label", `${this.removeLabelValue} ${fullLabel}`)
        pill.querySelector("[data-pill-label]").textContent = checkbox.dataset.label

        return pill
    }

    updateEmpty() {
        const query = this.inputTarget.value.trim()
        const isOpen = this.element.classList.contains("is-open")
        const noMatch = query !== "" && this.itemTargets.every(item => item.classList.contains("none"))

        this.listTarget.classList.toggle("is-no-match", noMatch)
        this.emptyTarget.classList.toggle("none", !(isOpen && noMatch))
    }

    // Only the search input, the list and the "not found" message keep the list open; the label and
    // the pills count as outside. Removing a pill re-renders the pills, so its click target is already
    // detached by the time this runs: that click leaves the list as it was.
    clickedInside(target) {
        if (!target.isConnected) return true

        return [ this.inputTarget, this.listTarget, this.emptyTarget ].some(part => part.contains(target))
    }

    normalizeString(str) {
        return (str || "")
            .normalize("NFD")
            .replace(/[̀-ͯ]/g, "")
            .replace(/[^a-z0-9]/gi, "")
            .toLowerCase()
    }
}
