import Zoombox from "@stimulus-components/dialog"

export default class extends Zoombox {
  static targets = ["dialog", "image"]

  open(event) {
    this.imageTarget.src = ""; // prevent flickering
    this.imageTarget.src = event.params.imgSrc;
    super.open(event);
  }
}
