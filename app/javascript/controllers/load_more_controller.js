import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
    static targets = ["trigger", "button", "pagination"]
    static values = { autoLoads: { type: Number, default: 3 } }

    connect() {
        this.autoLoadsRemaining = this.autoLoadsValue
        this.loading = false
        this.autoLoadArmed = false

        this.onScroll = () => {
            this.autoLoadArmed = true
            this.maybeAutoLoad()
        }
        window.addEventListener("scroll", this.onScroll, { passive: true })

        this.updatePaginationVisibility()

        this.mutationObserver = new MutationObserver(() => this.triggerUpdated())
        this.mutationObserver.observe(this.triggerTarget, { childList: true })
    }

    disconnect() {
        window.removeEventListener("scroll", this.onScroll)
        this.mutationObserver.disconnect()
    }

    loadMore(event) {
        event.preventDefault()
        this.fetchNextPage()
    }

    maybeAutoLoad() {
        if (!this.autoLoadArmed) return
        if (this.autoLoadsRemaining <= 0 || this.loading || !this.hasButtonTarget) return
        if (!this.triggerNearViewport()) return
        this.autoLoadsRemaining -= 1
        this.fetchNextPage()
    }

    triggerNearViewport(margin = 400) {
        const rect = this.triggerTarget.getBoundingClientRect()
        return rect.top < window.innerHeight + margin && rect.bottom > -margin
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
        this.updatePaginationVisibility()
    }

    updatePaginationVisibility() {
        if (!this.hasPaginationTarget) return
        const finished = this.autoLoadsRemaining <= 0 || !this.hasButtonTarget
        this.paginationTarget.hidden = !finished
    }

    setLoading(loading) {
        this.loading = loading
        this.triggerTarget.classList.toggle("is-loading", loading)
    }
}
