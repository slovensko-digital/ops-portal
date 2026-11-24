import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "item", "list", "empty"]
    static classes = ["none"]

    connect() {
        this.originalOrder = [...this.itemTargets]
    }

    // The open/close actions are for a dropdown list; the list stays put without them.
    open() {
        this.listTarget.classList.remove(this.noneClass)
        this.element.classList.add("is-open")
        this.updateEmpty()
    }

    close() {
        this.listTarget.classList.add(this.noneClass)
        this.element.classList.remove("is-open")
        this.inputTarget.value = ""
        this.reset()
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

    // Shows every item again in its original order; filter() moves matches to the end.
    reset() {
        this.originalOrder.forEach((el) => {
            el.classList.remove(this.noneClass)
            this.listTarget.appendChild(el)
        })
    }

    filter() {
        const query = this.normalizeString(this.inputTarget.value.trim())
        const items = this.itemTargets

        if (query === "") {
            this.reset()
            this.updateEmpty()
            return
        }

        items.forEach((el) => {
            const label = this.normalizeString(el.innerText.trim())
            const score = this.matchScore(label, query)

            el.dataset.score = score
            el.classList.toggle(this.noneClass, score === Infinity)
        })

        const visible = items
            .filter((el) => !el.classList.contains(this.noneClass))
            .sort((a, b) => a.dataset.score - b.dataset.score)

        visible.forEach((el) => this.listTarget.appendChild(el))
        this.updateEmpty()
    }

    // While the list is open and nothing matches, the "not found" message replaces the empty list.
    updateEmpty() {
        if (!this.hasEmptyTarget) return

        const query = this.inputTarget.value.trim()
        const isOpen = this.element.classList.contains("is-open")
        const noMatch = query !== "" && this.itemTargets.every(el => el.classList.contains(this.noneClass))

        this.listTarget.classList.toggle("is-no-match", noMatch)
        this.emptyTarget.classList.toggle(this.noneClass, !(isOpen && noMatch))
    }

    enter(event) {
        event.preventDefault()

        this.itemTargets.find(el => !el.classList.contains(this.noneClass))
            ?.querySelector("a")
            ?.click()
    }

    normalizeString(str) {
        return str
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
            .replace(/[^a-z0-9]/gi, "")
            .toLowerCase()
    }

    matchScore(label, query) {
        if (label.startsWith(query)) return 0
        if (label.includes(query)) return 5

        return Infinity
    }
}