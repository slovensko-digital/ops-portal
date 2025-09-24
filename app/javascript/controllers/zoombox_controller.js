import Zoombox from "@stimulus-components/dialog"

export default class extends Zoombox {
  static targets = ["dialog", "image"]

  connect() {
    super.connect();
    this.currentIndex = 0;
    this.startX = 0;
    this.threshold = 50;
  }

  open(event) {
    const group = event.params.group;

    this.images = Array.from(
      document.querySelectorAll(`[data-zoombox-group-param="${group}"]`)
    ).map(element => ({
      src: element.dataset.zoomboxImgSrcParam,
      index: parseInt(element.dataset.zoomboxImgIndexParam)
    }));

    this.currentIndex = parseInt(event.params.imgIndex);
    this.imageTarget.src = ""; // prevent flickering
    this.imageTarget.src = event.params.imgSrc;

    super.open(event);
    this.dialogTarget.focus()
    this.updateArrows();
  }

  prevImage(event = null) {
    if (event) event.stopPropagation();
    if (this.currentIndex > 0) {
      this.currentIndex--;
      this.updateImage();
    }
    this.dialogTarget.focus();
  }

  nextImage(event = null) {
    if (event) event.stopPropagation();
    if (this.currentIndex < this.images.length - 1) {
      this.currentIndex++;
      this.updateImage();
    }
    this.dialogTarget.focus();
  }

  updateImage() {
    const image = this.images.find(img => img.index === this.currentIndex);
    if (image) {
      this.imageTarget.src = "";
      this.imageTarget.src = image.src;
      this.updateArrows();
    }
  }

  updateArrows() {
    const prevButton = this.dialogTarget.querySelector('.left-arrow');
    const nextButton = this.dialogTarget.querySelector('.right-arrow');

    if (this.images.length <= 1) {
      prevButton.style.display = "none";
      nextButton.style.display = "none";
      return;
    }

    prevButton.style.display = "block";
    nextButton.style.display = "block";

    prevButton.disabled = this.currentIndex === 0;
    nextButton.disabled = this.currentIndex === this.images.length - 1;

    prevButton.style.opacity = this.currentIndex === 0 ? '0.3' : '1';
    nextButton.style.opacity = this.currentIndex === this.images.length - 1 ? '0.3' : '1';
  }

  touchStart(event) {
    this.startX = event.changedTouches[0].screenX;
  }

  touchEnd(event) {
    const endX = event.changedTouches[0].screenX;
    const deltaX = endX - this.startX;

    if (Math.abs(deltaX) > this.threshold) {
      if (deltaX > 0) {
        this.prevImage();
      } else {
        this.nextImage();
      }
    }
  }
}
