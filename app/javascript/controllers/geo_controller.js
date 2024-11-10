import {Controller} from "@hotwired/stimulus"
import "leaflet"
import "leaflet-css"

// Connects to data-controller="geo"
export default class extends Controller {
    static targets = ["latitude", "longitude", "map"]

    connect() {
        this.map = L.map(this.mapTarget)
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(this.map);

        let place = [this.latitudeTarget.value, this.longitudeTarget.value];
        let zoom = 17;
        if (place[0] === '' || place[1] === '') {
            place = [48.148598, 17.107748]
            zoom = 12;
        }

        this.map.setView(place, zoom)
        this.map.addEventListener('moveend', this.setInputs.bind(this));
    }

    setInputs() {
        const pos = this.map.getCenter();
        this.latitudeTarget.value = pos.lat;
        this.longitudeTarget.value = pos.lng;
    }

    showOnMap() {
        const place = [this.latitudeTarget.value, this.longitudeTarget.value];
        this.map.setView(place, 18);
    }

    locate() {
        const options = {
            enableHighAccuracy: false,
            maximumAge: 0
        };

        navigator.geolocation.getCurrentPosition(this.onSuccess.bind(this), this.onError, options);

        this.showOnMap();
    }

    onSuccess(location) {
        this.latitudeTarget.value = location.coords.latitude;
        this.longitudeTarget.value = location.coords.longitude;
    }

    onError(error) {
        console.log(error);
    }

    disconnect() {
        this.map.remove();
    }
}
