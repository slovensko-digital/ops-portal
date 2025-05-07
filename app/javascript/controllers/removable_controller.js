import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="uploads"
export default class extends Controller {
  static targets = ["removable"]
  connect() {
  }

  remove(event) {
    event.preventDefault();
    var confirmed = true;
    if(event.params.confirm) {
      confirmed = confirm(event.params.confirm);
    }
    if(!confirmed) return false;

    this.removableTarget.remove();
  }
}
