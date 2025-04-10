import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="carousel"
export default class extends Controller {
    static targets = ["next", "previous", "slide"]

    connect() {
        this.currentSlide = 0
    }

    showSlide(index) {
        // Hide all slides
        this.slideTargets.forEach(slide => {
            slide.style.display = "none"
        })

        // Show current slide
        this.slideTargets[index].style.display = "grid"

        const isLastSlide = index + 1 >= this.slideTargets.length;
        const isFirstSlide = index === 0;

        this.previousTargets.forEach(e => {
            e.classList.toggle('inactive', isFirstSlide);
        });

        this.nextTargets.forEach(e => {
            e.classList.toggle('inactive', isLastSlide);
        });
    }

    next(event) {
        event.preventDefault();
        if (this.currentSlide + 1 >= this.slideTargets.length) return;
        this.currentSlide += 1
        this.showSlide(this.currentSlide)
    }

    previous(event) {
        event.preventDefault();
        if (this.currentSlide === 0) return;
        this.currentSlide -= 1
        this.showSlide(this.currentSlide)
    }
}