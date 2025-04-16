import {Controller} from "@hotwired/stimulus"
import "leaflet"

// Connects to data-controller="geo"
export default class extends Controller {
    static values = {latitude: Number, longitude: Number}
    static targets = ["map"]

    connect() {
        this.map = L.map(this.mapTarget, {dragging: !L.Browser.mobile, scrollWheelZoom: false})
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19, attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(this.map);

        L.circle([this.latitudeValue, this.longitudeValue], {
            color: '#ff4761',
            fillColor: '#ff4761',
            fillOpacity: 0.3,
            radius: 5
        }).addTo(this.map);

        const place = [this.latitudeValue, this.longitudeValue];
        const zoom = 17;

        this.map.setView(place, zoom);
    }

    disconnect() {
        this.map.remove();
    }
}
