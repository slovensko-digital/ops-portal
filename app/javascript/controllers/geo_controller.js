import {Controller} from "@hotwired/stimulus"
import "leaflet"
import {LocateControl} from "leaflet.locatecontrol";

// Connects to data-controller="geo"
export default class extends Controller {
    static targets = ["latitude", "longitude", "zoom", "map", "search", "localize", "support"]
    static classes = ["supported"]

    connect() {
        if (navigator.geolocation !== undefined) {
            this.supportTargets.forEach(target => target.classList.add(this.supportedClass));
        }

        this.map = L.map(this.mapTarget)
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(this.map);

        new LocateControl({strings: {title: 'Aktuálna poloha'}}).addTo(this.map);

        let place = [this.latitudeTarget.value, this.longitudeTarget.value];
        let zoom = this.zoomTarget.value || 17;
        if (place[0] === '' || place[1] === '') {
            place = [48.148598, 17.107748]
            zoom = 12;
        }

        this.map.setView(place, zoom);
        this.map.addEventListener('moveend', this.setInputs.bind(this));
    }

    setInputs() {
        const pos = this.map.getCenter();
        this.latitudeTarget.value = pos.lat;
        this.longitudeTarget.value = pos.lng;
        this.zoomTarget.value = this.map.getZoom();
    }

    search(event) {
        event.preventDefault();
        var form = event.target.closest('form')
        form.ariaBusy = true;
        fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${this.searchTarget.value}&accept-language=sk&countrycodes=sk`, {
            headers: {'User-Agent': 'www.odkazprestarostu.sk'}
        }).then(response => response.json())
            .then(data => {
                const place = data[0];
                this.latitudeTarget.value = place.lat;
                this.longitudeTarget.value = place.lon;
                this.map.fitBounds([
                    [place.boundingbox[0], place.boundingbox[2]],
                    [place.boundingbox[1], place.boundingbox[3]]
                ]);
                form.ariaBusy = false;
            })
            .catch(() => {
                form.ariaBusy = false;
            });
    }

    localize(event) {
        event.preventDefault();
        if (!navigator.geolocation) {
            alert("Geolokácia nie je podporovaná vo vašom prehliadači.");
            return;
        }
        // Get current position from GPS or fallback to defaults
        navigator.geolocation.getCurrentPosition(
            (position) => {
                const lat = position.coords.latitude;
                const lng = position.coords.longitude;

                // Update form inputs
                this.latitudeTarget.value = lat;
                this.longitudeTarget.value = lng;

                // Update map view
                this.map.setView([lat, lng], 17);
            },
            (error) => {
                // Fallback to data attributes or defaults if GPS fails
                alert("Nepodarilo sa získať GPS pozíciu.")
            }
        );
    }

    disconnect() {
        this.map.remove();
    }
}
