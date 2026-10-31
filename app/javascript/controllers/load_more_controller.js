import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
    static targets = ["trigger", "button"]

    connect() {
        this.loading = false;
        [this.firstPage, this.lastPage] = this.parsePageRange()

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

        const loadedPage = this.pageParam(new URL(url, window.location.origin))
        if (loadedPage !== null && loadedPage > this.lastPage) {
            this.lastPage = loadedPage
            this.updateUrl()
        }

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

    parsePageRange() {
        const param = new URLSearchParams(window.location.search).get("page")
        const range = param && param.match(/^(\d+)-(\d+)$/)
        if (range) {
            const first = Math.max(1, parseInt(range[1], 10))
            return [first, Math.max(first, parseInt(range[2], 10))]
        }
        if (param && /^\d+$/.test(param)) {
            const page = Math.max(1, parseInt(param, 10))
            return [page, page]
        }
        return [1, 1]
    }

    pageParam(url) {
        const page = parseInt(url.searchParams.get("page"), 10)
        return Number.isSafeInteger(page) && page >= 1 ? page : null
    }

    updateUrl() {
        const url = new URL(window.location.href)
        url.searchParams.set("page", this.firstPage === this.lastPage ? String(this.lastPage) : `${this.firstPage}-${this.lastPage}`)
        window.history.replaceState(null, "", url)
    }
}
