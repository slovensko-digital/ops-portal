import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
    static targets = ["trigger", "button"]

    connect() {
        this.loading = false

        this.mutationObserver = new MutationObserver(() => this.triggerUpdated())
        this.mutationObserver.observe(this.triggerTarget, { childList: true })
    }

    disconnect() {
        this.mutationObserver.disconnect()
    }

    loadMore(event) {
        event.preventDefault()
        this.fetchNextPage()
    }

    async fetchNextPage() {
        if (this.loading || !this.hasButtonTarget) return

        const url = this.buttonTarget.getAttribute("href")
        if (!url) return

        this.setLoading(true)

        try {
            const response = await fetch(url, {
                headers: { Accept: "text/vnd.turbo-stream.html" }
            })
            if (!response.ok) throw new Error(`HTTP ${response.status}`)
            const before = this.triggerTarget.innerHTML
            Turbo.renderStreamMessage(await response.text())
            if (this.triggerTarget.innerHTML === before) {
                this.setLoading(false)
            }
        } catch {
            this.setLoading(false)
        }
    }

    triggerUpdated() {
        this.setLoading(false)
    }

    setLoading(loading) {
        this.loading = loading
        this.triggerTarget.classList.toggle("is-loading", loading)
    }
}
