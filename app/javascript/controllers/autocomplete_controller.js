import SearchableSelectController from "controllers/searchable_select_controller"

// A flat searchable list: matches that start with the query come first.
export default class extends SearchableSelectController {
    connect() {
        this.originalOrder = [...this.itemTargets]
    }

    // Shows every item again in its original order; showMatches() moves matches to the end.
    showAll() {
        this.originalOrder.forEach(item => {
            item.classList.remove("none")
            this.listTarget.appendChild(item)
        })
    }

    showMatches(query) {
        const items = this.itemTargets

        items.forEach(item => {
            const score = this.matchScore(this.normalizeString(item.innerText.trim()), query)

            item.dataset.score = score
            item.classList.toggle("none", score === Infinity)
        })

        items
            .filter(item => !item.classList.contains("none"))
            .sort((a, b) => a.dataset.score - b.dataset.score)
            .forEach(item => this.listTarget.appendChild(item))
    }

    matchScore(label, query) {
        if (label.startsWith(query)) return 0
        if (label.includes(query)) return 5

        return Infinity
    }
}
