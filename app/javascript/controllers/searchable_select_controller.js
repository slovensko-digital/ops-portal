import SelectController from "controllers/select_controller"

// A select with a search input: typing filters the items and "Nič sme nenašli." shows when nothing
// matches (when the element has an empty target). Subclasses decide what matches in showMatches(query).
export default class SearchableSelectController extends SelectController {
    static targets = [ "input", "item", "empty" ]

    open() {
        super.open()
        this.updateEmpty()
    }

    close() {
        super.close()
        this.inputTarget.value = ""
        this.showAll()
        this.updateEmpty()
    }

    filter() {
        const query = this.normalizeString(this.inputTarget.value.trim())
        this.open()

        if (query === "") {
            this.showAll()
        } else {
            this.showMatches(query)
        }

        this.updateEmpty()
    }

    // Enter follows the first visible item instead of submitting a form.
    enter(event) {
        event.preventDefault()

        this.itemTargets.find(item => !item.classList.contains("none"))?.querySelector("a")?.click()
    }

    showAll() {
        this.itemTargets.forEach(item => item.classList.remove("none"))
    }

    showMatches(query) {
        this.itemTargets.forEach(item => {
            item.classList.toggle("none", !this.normalizeString(item.innerText).includes(query))
        })
    }

    updateEmpty() {
        if (!this.hasEmptyTarget) return

        const query = this.inputTarget.value.trim()
        const noMatch = query !== "" && this.itemTargets.every(item => item.classList.contains("none"))

        this.listTarget.classList.toggle("is-no-match", noMatch)
        this.emptyTarget.classList.toggle("none", !(this.isOpen && noMatch))
    }

    normalizeString(str) {
        return (str || "")
            .normalize("NFD")
            .replace(/[̀-ͯ]/g, "")
            .replace(/[^a-z0-9]/gi, "")
            .toLowerCase()
    }
}
