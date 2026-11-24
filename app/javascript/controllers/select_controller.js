import { Controller } from "@hotwired/stimulus"

// A custom select: a list that opens under its field and closes on Esc or a click outside.
// The searchable ones build on it: searchable_select_controller.js.
export default class SelectController extends Controller {
    static targets = [ "list" ]

    get isOpen() {
        return this.element.classList.contains("is-open")
    }

    open() {
        this.listTarget.classList.remove("none")
        this.element.classList.add("is-open")
    }

    close() {
        this.listTarget.classList.add("none")
        this.element.classList.remove("is-open")
    }

    toggle() {
        if (this.isOpen) {
            this.close()
        } else {
            this.open()
        }
    }

    closeOnEscape() {
        if (!this.isOpen) return

        this.close()
        if (this.element.contains(document.activeElement)) document.activeElement.blur()
    }

    closeOnOutsideClick(event) {
        if (!this.isOpen) return
        if (this.clickedInside(event.target)) return

        this.close()
    }

    // A click on an element that is no longer on the page (a re-rendered pill) counts as inside.
    clickedInside(target) {
        return !target.isConnected || this.element.contains(target)
    }
}
