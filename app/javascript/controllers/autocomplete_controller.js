import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "item", "list"]
    static classes = ["none"]

    filter() {
        const query = this.normalizeString(this.inputTarget.value.trim())
        const items = this.itemTargets

        if (query === "") {
            items.forEach((el) => el.classList.remove(this.noneClass))
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