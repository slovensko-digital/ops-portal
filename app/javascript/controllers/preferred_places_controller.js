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

    filter() {
        const query = this.inputTarget.value.toLowerCase().trim()
        this.open()

        this.itemTargets.forEach(item => {
            const text = item.textContent.toLowerCase()
            if (text.includes(query)) {
                item.classList.remove("none")
            } else {
                item.classList.add("none")
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

        const names = checkedBoxes.map(cb => cb.dataset.label)

        if (names.length <= 2) {
            this.inputTarget.placeholder = names.join(", ")
        } else {
            this.inputTarget.placeholder = `${names.slice(0, 2).join(", ")} a ďalšie`
        }
    }
}
