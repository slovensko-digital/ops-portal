import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="dismiss"
export default class extends Controller {
    static values = {
        delay: {type: Number, default: 5000}
    }

    connect() {
        this.timeout = setTimeout(() => {
            this.element.style.opacity = 0

        }, this.delayValue)
    }

    disconnect() {
        if (this.timeout) {
            clearTimeout(this.timeout)
        }
    }
}