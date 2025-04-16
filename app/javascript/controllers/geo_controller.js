import {Controller} from "@hotwired/stimulus"
import "leaflet"
import {LocateControl} from "leaflet.locatecontrol";

// Connects to data-controller="geo"
export default class extends Controller {
    static targets = ["latitude", "longitude", "map", "search"]

    connect() {
        this.map = L.map(this.mapTarget)
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(this.map);

        new LocateControl({strings: {title: 'Aktuálna poloha'}}).addTo(this.map);

        let place = [this.latitudeTarget.value, this.longitudeTarget.value];
        let zoom = 17;
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
    }

    search(event) {
        event.preventDefault();
        fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${this.searchTarget.value}&accept-language=sk`, {
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
            });
    }

    disconnect() {
        this.map.remove();
    }
}
