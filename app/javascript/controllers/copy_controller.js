import { Controller } from "@hotwired/stimulus"

const COPY_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="16" height="16"><path d="M16 1H4a2 2 0 00-2 2v14h2V3h12V1zm3 4H8a2 2 0 00-2 2v14a2 2 0 002 2h11a2 2 0 002-2V7a2 2 0 00-2-2zm0 16H8V7h11v14z"/></svg>`;
const CHECK_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="16" height="16"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"/></svg>`;

export default class extends Controller {
  static values = { content: String }
  static targets = ["iconContainer"]

  async copy() {
    const textToCopy = this.contentValue;

    await navigator.clipboard.writeText(textToCopy);

    this.iconContainerTarget.innerHTML = CHECK_SVG;
    setTimeout(() => {
      this.iconContainerTarget.innerHTML = COPY_SVG;
    }, 1500);
  }
}