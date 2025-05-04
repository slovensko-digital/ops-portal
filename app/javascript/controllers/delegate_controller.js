import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="delegate"
export default class extends Controller {
    static targets = ["selectorRoot"]
    static values = {
        selector: String
    }

    connect() {
    }

    click(event) {
        event.preventDefault();

        const startElement = this.selectorRootTarget;
        const targetElement = startElement.querySelector(event.params.selector);
        if (targetElement) {
            targetElement.click();
        }
    }
}