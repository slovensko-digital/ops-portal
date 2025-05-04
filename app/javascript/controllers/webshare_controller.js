import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        title: String,
        text: String,
        url: {type: String}
    }

    static classes = ["supported"]

    connect() {
        if (navigator.share !== undefined) {
            this.element.classList.add(this.supportedClass);
        }
    }

    share(event) {
        event.preventDefault();

        const shareData = {
            title: this.titleValue || document.title,
            text: this.textValue || "",
            url: this.urlValue
        }

        navigator.share(shareData)
            .then(() => console.log("Shared successfully"))
            .catch((error) => {
                console.log("Error sharing:", error)
            })
    }
}
