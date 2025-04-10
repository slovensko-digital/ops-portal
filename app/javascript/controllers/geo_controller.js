import {Controller} from "@hotwired/stimulus"
import "leaflet"
import "leaflet-css"

// Connects to data-controller="geo"
export default class extends Controller {
    static targets = ["latitude", "longitude", "map",
        "address", "addressHouseNumber", "addressRoad", "addressNeighbourhood", "addressTown", "addressSuburb",
        "addressCityDistrict", "addressCity", "addressState", "addressPostcode", "addressCountry", "addressCountryCode",
        "addressVillage", "addressCounty",
        "addressFull"
    ]

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

        this.map.setView(place, zoom);
        this.fetchAddress();
        this.map.addEventListener('moveend', this.setInputs.bind(this));
        this.map.addEventListener('moveend', this.fetchAddress.bind(this));
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

    fetchAddress() {
        fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${this.latitudeTarget.value}&lon=${this.longitudeTarget.value}&accept-language=sk`, {
            headers: {'User-Agent': 'OPS'}
        })
            .then(response => response.json())
            .then(data => {
                this.addressHouseNumberTargets.forEach(target => target.value = data.address.house_number || '');
                this.addressRoadTargets.forEach(target => target.value = data.address.road || '');
                this.addressNeighbourhoodTargets.forEach(target => target.value = data.address.neighbourhood || '');
                this.addressTownTargets.forEach(target => target.value = data.address.town || '');
                this.addressSuburbTargets.forEach(target => target.value = data.address.suburb || '');
                this.addressCityDistrictTargets.forEach(target => target.value = data.address.city_district || '');
                this.addressCityTargets.forEach(target => target.value = data.address.city || '');
                this.addressStateTargets.forEach(target => target.value = data.address.state || '');
                this.addressPostcodeTargets.forEach(target => target.value = data.address.postcode || '');
                this.addressCountryTargets.forEach(target => target.value = data.address.country || '');
                this.addressCountryCodeTargets.forEach(target => target.value = data.address.country_code || '');
                this.addressCountyTargets.forEach(target => target.value = data.address.county || '');
                this.addressVillageTargets.forEach(target => target.value = data.address.village || '');
                this.addressFullTargets.forEach(target => target.value = data.display_name || '');
                this.addressTargets.forEach(target => target.innerText = data.display_name || '');
            });
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
