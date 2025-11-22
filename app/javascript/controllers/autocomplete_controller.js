import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "item", "list"]

    filter() {
        const query = this.normalizeString(this.inputTarget.value.trim())
        const items = this.itemTargets

        if (query === "") {
            items.forEach((el) => el.classList.remove("none"))
            return
        }

        items.forEach((el) => {
            const label = this.normalizeString(el.innerText.trim())
            const score = this.matchScore(label, query)

            el.dataset.score = score
            el.classList.toggle("none", score === Infinity)
        })

        const visible = items
            .filter((el) => !el.classList.contains("none"))
            .sort((a, b) => a.dataset.score - b.dataset.score)

        visible.forEach((el) => this.listTarget.appendChild(el))
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

        const d = this.levenshtein(label, query)
        return d <= 3 ? 10 + d : Infinity
    }

    levenshtein(a, b) {
        const m = []
        for (let i = 0; i <= b.length; i++) m[i] = [i]
        for (let j = 1; j <= a.length; j++) m[0][j] = j

        for (let i = 1; i <= b.length; i++) {
            for (let j = 1; j <= a.length; j++) {
                m[i][j] =
                    b[i - 1] === a[j - 1]
                        ? m[i - 1][j - 1]
                        : 1 + Math.min(m[i - 1][j], m[i][j - 1], m[i - 1][j - 1])
            }
        }

        return m[b.length][a.length]
    }
}
