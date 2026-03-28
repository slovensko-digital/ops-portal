import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="remote-autocomplete"

export default class extends Controller {
    static targets = ["input", "results", "hidden", "template"]
    static values = { url: String }
    static classes = ["none"]

    connect() {
        this.timeout = null
    }

    search(event) {
        if (event?.isComposing) {
            return
        }

        clearTimeout(this.timeout)
        const query = this.inputTarget.value.trim()

        if (query.length < 1) {
            this.hideResults()
            return
        }

        this.timeout = setTimeout(() => this.fetchResults(query), 300)
    }

    async fetchResults(query) {
        const url = new URL(this.urlValue, window.location.origin)
        url.searchParams.set("q", query)

        const response = await fetch(url)
        const data = await response.json()
        this.renderResults(data)
    }


    renderResults(items) {
        this.resultsTarget.innerHTML = ""

        if (items.length === 0) {
            this.hideResults()
            return
        }

        items.forEach(item => {
            const content = this.templateTarget.content.cloneNode(true)
            const link = content.querySelector("a")

            link.textContent = item.name

            link.dataset.remoteAutocompleteIdParam = item.id
            link.dataset.remoteAutocompleteNameParam = item.name

            this.resultsTarget.appendChild(content)
        })

        this.resultsTarget.classList.remove(this.noneClass)
        this.resultsTarget.style.display = "block"
    }


    select(event) {
        event.preventDefault()

        this.inputTarget.value = event.params.name
        this.hiddenTarget.value = event.params.id
        this.hideResults()
    }


    hideResults() {
        this.resultsTarget.classList.add(this.noneClass)
        this.resultsTarget.style.display = "none"
    }


    hide(event) {
        if (!this.element.contains(event.target)) {
            this.hideResults()
        }
    }
}