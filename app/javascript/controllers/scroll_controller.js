import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll"
export default class extends Controller {
  connect() {
  }

  scroll() {
    this.element.scrollIntoView({ behavior: "smooth" });
  }
}
