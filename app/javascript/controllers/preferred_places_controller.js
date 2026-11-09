import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "input", "list", "checkbox", "item" ]
    static values = {
        defaultPlaceholder: { type: String, default: "Vyhľadajte lokality..." }
    }

    connect() {
        this.updatePlaceholder()
    }

    open() {
        this.listTarget.classList.remove("none")
    }

    close(event) {
        if (!this.element.contains(event.target)) {
            this.listTarget.classList.add("none")
        }
    }

    enter(event) {
        event.preventDefault()
    }

    filter() {
        const query = this.normalizeString(this.inputTarget.value.trim())
        this.open()

        if (query === "") {
            this.itemTargets.forEach(item => item.classList.remove("none"))
            return
        }

        let currentMunicipalityItem = null
        let currentMunicipalityMatch = false

        this.itemTargets.forEach(item => {
            const checkbox = item.querySelector('[data-preferred-places-target="checkbox"]')
            const fullLabel = checkbox?.dataset.fullLabel || item.textContent
            const isDistrict = fullLabel.includes(" - ")
            const normalized = this.normalizeString(fullLabel.trim())

            if (!isDistrict) {
                currentMunicipalityItem = item
                currentMunicipalityMatch = normalized.includes(query)
                item.classList.toggle("none", !currentMunicipalityMatch)
            } else {
                const districtMatch = normalized.includes(query)
                const showDistrict = districtMatch || currentMunicipalityMatch
                item.classList.toggle("none", !showDistrict)

                if (districtMatch && currentMunicipalityItem) {
                    currentMunicipalityItem.classList.remove("none")
                }
            }
        })
    }

    toggle(event) {
        const checkbox = event.target
        const li = checkbox.closest("li")

        if (li) {
            li.classList.toggle("active", checkbox.checked)
        }

        this.updatePlaceholder()
    }

    updatePlaceholder() {
        const checkedBoxes = this.checkboxTargets.filter(cb => cb.checked)

        if (checkedBoxes.length === 0) {
            this.inputTarget.placeholder = this.defaultPlaceholderValue
            return
        }

        const names = checkedBoxes.map(cb => cb.dataset.fullLabel)

        if (names.length <= 2) {
            this.inputTarget.placeholder = names.join(", ")
        } else {
            this.inputTarget.placeholder = `${names.slice(0, 2).join(", ")} a ďalšie`
        }
    }

    normalizeString(str) {
        return (str || "")
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
            .replace(/[^a-z0-9]/gi, "")
            .toLowerCase()
    }
}
