import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navigation"
export default class extends Controller {
  static targets = ["toggler"]

  open(event) {
    this.togglerTarget.classList.add("open-nav-body");
  }

  close(event) {
    this.togglerTarget.classList.remove("open-nav-body");
  }
}
