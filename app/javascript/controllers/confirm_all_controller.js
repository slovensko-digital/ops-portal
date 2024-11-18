import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="confirm-all"
export default class extends Controller {
    static targets = ["continue"]

    confirm(event) {
        event.target.closest(".group").remove();
        if (this.element.getElementsByClassName("group").length == 0) {
            this.continueTarget.classList.remove("hidden");
        }
    }
}
