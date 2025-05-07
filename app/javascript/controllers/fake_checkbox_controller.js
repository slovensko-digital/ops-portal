import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="fake-checkbox"
export default class extends Controller {
  static targets = ["checkbox"]

  clickCheckbox() {
    this.checkboxTarget.click()
  }
}
