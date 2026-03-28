import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="propagation"
export default class extends Controller {
    stop(event) {
        event.stopPropagation()
    }
}
