import { Controller } from "@hotwired/stimulus"

// Search filter "Obec / Mestská časť": a municipality followed by its districts. Filtering keeps the
// tree order: a matching district keeps its municipality visible, and a matching municipality shows
// all of its districts (district names repeat across cities, so the parent tells them apart).
export default class extends Controller {
    static targets = [ "input", "list", "item", "empty" ]

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

    closeOnEscape() {
        if (!this.element.classList.contains("is-open")) return

        this.close()
        this.inputTarget.blur()
    }

    closeOnOutsideClick(event) {
        if (!this.element.classList.contains("is-open")) return
        if (this.element.contains(event.target)) return

        this.close()
    }

    enter(event) {
        event.preventDefault()

        this.itemTargets.find(item => !item.classList.contains("none"))?.querySelector("a")?.click()
    }

    filter() {
        const query = this.normalizeString(this.inputTarget.value.trim())
        this.open()

        if (query === "") {
            this.itemTargets.forEach(item => item.classList.remove("none"))
            this.updateEmpty()
            return
        }

        let municipalityItem = null
        let municipalityMatch = false

        this.itemTargets.forEach(item => {
            const match = this.normalizeString(item.dataset.fullLabel).includes(query)

            if (item.dataset.level === "0") {
                municipalityItem = item
                municipalityMatch = match
                item.classList.toggle("none", !match)
            } else {
                item.classList.toggle("none", !(match || municipalityMatch))
                if (match) municipalityItem?.classList.remove("none")
            }
        })

        this.updateEmpty()
    }

    updateEmpty() {
        const query = this.inputTarget.value.trim()
        const isOpen = this.element.classList.contains("is-open")
        const noMatch = query !== "" && this.itemTargets.every(item => item.classList.contains("none"))

        this.listTarget.classList.toggle("is-no-match", noMatch)
        this.emptyTarget.classList.toggle("none", !(isOpen && noMatch))
    }

    normalizeString(str) {
        return (str || "")
            .normalize("NFD")
            .replace(/[̀-ͯ]/g, "")
            .replace(/[^a-z0-9]/gi, "")
            .toLowerCase()
    }
}
