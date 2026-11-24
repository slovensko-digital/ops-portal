import TreeAutocompleteController from "controllers/tree_autocomplete_controller"

// Profile "Preferované mestá alebo obce": the searchable tree of tree_autocomplete_controller.js with
// checkboxes, and the selection shown as removable pills above the search input. A district pill
// shows only the district name; the full "Municipality - District" name is in its title and
// aria-label (district names repeat across cities).
export default class extends TreeAutocompleteController {
    static targets = [ "checkbox", "pills", "pillTemplate", "count" ]
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

    // The checked inputs are exactly what gets saved: a whole municipality, or some of its districts.
    // - A checked municipality shows all its districts as ticked, but only the municipality is saved.
    // - Unticking one of those districts unchecks the municipality and checks the other districts,
    //   so the municipality becomes partial (shown as "-").
    // - Ticking the last missing district collapses back to the whole municipality.
    toggleLocality(event) {
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

    // Only the search input, the list and the "not found" message keep the list open; the label and
    // the pills count as outside. Removing a pill re-renders the pills, so its click target is already
    // detached by the time this runs: that click leaves the list as it was.
    clickedInside(target) {
        if (!target.isConnected) return true

        return [ this.inputTarget, this.listTarget, this.emptyTarget ].some(part => part.contains(target))
    }
}
