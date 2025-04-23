import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="intercept"
export default class extends Controller {
    static targets = ["interceptable", "anchor"]
    static values = {toggleClass: String, default: "shadow"}

    connect() {
        this.observer = new IntersectionObserver(([entry]) => {
            this.interceptableTarget.classList.toggle(this.toggleClassValue, !entry.isIntersecting);
        });

        this.observer.observe(this.anchorTarget);
    }

    disconnect() {
        this.observer.disconnect();
    }
}
