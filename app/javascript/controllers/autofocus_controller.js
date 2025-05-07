import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "scrollAnchor"]
  connect() {
    if( this.hasScrollAnchorTarget ) {
      this.scrollAnchorTarget.scrollIntoView({block: "center", behavior: "smooth"});
    }
    this.inputTarget.focus();
  }
}
