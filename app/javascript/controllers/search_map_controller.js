import {Controller} from "@hotwired/stimulus"
import L from 'leaflet';

export default class extends Controller {
    static targets = ["map"]
    static values = {geoJsonUrl: String, baseSearchUrl: String, bboxFilter: String, geoFilterParam: String, pin: String}

    connect() {
        const map = L.map(this.mapTarget, {
            dragging: !L.Browser.mobile,
            maxZoom: 19
        }).fitBounds([[47.483, 15.781], [50.032, 22.813]]);
        let geoJsonLayer;
        let isInitialLoad = true;

        L.tileLayer('https://a.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap',
            maxNativeZoom: 18,
            maxZoom: 19,
        }).addTo(map);

        // Display bbox filter as rectangle if present
        if (this.bboxFilterValue && this.bboxFilterValue.trim()) {
            const coords = this.bboxFilterValue.split(',').map(coord => parseFloat(coord.trim()));
            if (coords.length === 4) {
                const [minX, minY, maxX, maxY] = coords;
                const bounds = [[minY, minX], [maxY, maxX]];

                L.rectangle(bounds, {
                    color: '#007bff',
                    weight: 2,
                    fillColor: '#007bff',
                    fillOpacity: 0.1,
                    dashArray: '5, 5'
                }).addTo(map);
            }
        }

        // Display pin as blue circle if present
        if (this.pinValue && this.pinValue.trim()) {
            const coords = this.pinValue.split(',').map(coord => parseFloat(coord.trim()));
            if (coords.length === 2) {
                const [lat, lng] = coords;

                const pinIcon = L.divIcon({
                    html: `<div style="color: #000;">
                             <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" width="20" height="20" fill="currentColor">
                               <circle cx="10" cy="10" r="1.5"></circle>
                               <path d="M19.75,9.25h-2.04c-.35-3.68-3.29-6.61-6.96-6.96V.25h-1.5v2.04c-3.68.35-6.61,3.29-6.96,6.96H.25v1.5h2.04c.35,3.68,3.29,6.61,6.96,6.96v2.04h1.5v-2.04c3.68-.35,6.61-3.29,6.96-6.96h2.04v-1.5ZM10.75,16.2v-1.95h-1.5v1.95c-2.85-.34-5.11-2.6-5.45-5.45h1.95v-1.5h-1.95c.34-2.85,2.6-5.11,5.45-5.45v1.95h1.5v-1.95c2.85.34,5.11,2.6,5.45,5.45h-1.95v1.5h1.95c-.34,2.85-2.6,5.11-5.45,5.45Z"></path>
                             </svg>
                           </div>`,
                    className: 'custom-pin-icon',
                    iconSize: [20, 20],
                    iconAnchor: [10, 10]
                });

                L.marker([lat, lng], { icon: pinIcon }).addTo(map);
            }
        }

        const loadGeoJson = () => {
            const baseUrl = this.geoJsonUrlValue;
            const separator = baseUrl.includes('?') ? '&' : '?';
            const url = `${baseUrl}${separator}z=${map.getZoom()}&bbox=${map.getBounds().toBBoxString()}`;

            fetch(url)
                .then(response => response.json())
                .then(data => {
                    if (geoJsonLayer) {
                        map.removeLayer(geoJsonLayer);
                    }
                    geoJsonLayer = L.geoJSON(data, {
                        pointToLayer: function (feature, latlng) {
                            if (feature.properties.count > 1) {
                                const marker = L.marker(latlng, {
                                    icon: L.divIcon({
                                        html: `<div class="cluster-marker">
                                                 <div class="cluster-marker-inner">${feature.properties.nice_count}</div>
                                               </div>`,
                                        className: 'custom-cluster-icon',
                                        iconSize: [50, 50],
                                        iconAnchor: [25, 25]
                                    })
                                });
                                return marker;
                            } else {
                                const radius = map.getZoom() > 18 ? 10 : 6;

                                const marker = L.circleMarker(latlng, {
                                    color: '#ff4761',
                                    fillColor: '#ff4761',
                                    fillOpacity: 0.3,
                                    radius: radius
                                });
                                marker.on('mouseover', function () {
                                    this.setStyle({
                                        radius: radius,
                                        fillColor: '#00F',
                                        color: '#00F',
                                        fillOpacity: 0.5
                                    });
                                });
                                marker.on('mouseout', function () {
                                    this.setStyle({
                                        color: '#ff4761',
                                        fillColor: '#ff4761',
                                        fillOpacity: 0.3,
                                        radius: radius
                                    });
                                });
                                return marker;
                            }
                        },

                        onEachFeature: function (feature, layer) {
                            if (feature.properties.count === 0) {
                            } else if (feature.properties.count === 1) {
                                const popupContent = `
                                <a href="${feature.properties.url}" class="map-popup">
                                    <div class="title">${feature.properties.title}</div>
                                    <div class="location">${feature.properties.address}</div>
                                    <div class="date">${feature.properties.created_at}</div>
                                </a>
                            `;
                                layer.bindPopup(popupContent);
                                if (L.Browser.mobile) {
                                    layer.on('click', function () {
                                        this.openPopup();
                                    });
                                } else {
                                    layer.on('mouseover', function () {
                                        this.openPopup();
                                    });

                                    layer.on('mouseout', function () {
                                        this.closePopup();
                                    });

                                    layer.on('click', function () {
                                        window.location.href = feature.properties.url;
                                    });
                                }
                            } else {
                                layer.on('click', function () {
                                    const bounds = [
                                        [feature.properties.min_latitude, feature.properties.min_longitude],
                                        [feature.properties.max_latitude, feature.properties.max_longitude]
                                    ];
                                    map.fitBounds(bounds, {
                                        animate: true,
                                        duration: 0.2,
                                        padding: [20, 20]
                                    });
                                });
                            }
                        }
                    }).addTo(map);

                    // Fit bounds on initial load
                    if (isInitialLoad && geoJsonLayer.getLayers().length > 0) {
                        const bounds = [[
                            Math.min(...geoJsonLayer.getLayers().map(layer => layer.feature.properties.min_latitude || layer.getLatLng().lat)),
                            Math.min(...geoJsonLayer.getLayers().map(layer => layer.feature.properties.min_longitude || layer.getLatLng().lng))
                        ], [
                            Math.max(...geoJsonLayer.getLayers().map(layer => layer.feature.properties.max_latitude || layer.getLatLng().lat)),
                            Math.max(...geoJsonLayer.getLayers().map(layer => layer.feature.properties.max_longitude || layer.getLatLng().lng))
                        ]];
                        map.fitBounds(bounds, {
                            padding: [0, 0]
                        });
                        isInitialLoad = false;
                    }
                });
        };

        map.on('zoomend', loadGeoJson);
        map.on('moveend', loadGeoJson);
        loadGeoJson();

        // Store map reference for use in other methods
        this.map = map;
    }

    geofilter() {
        const currentBounds = this.map.getBounds();
        const url = new URL(this.baseSearchUrlValue, window.location.origin);
        url.searchParams.set(this.geoFilterParamValue, currentBounds.toBBoxString());

        Turbo.visit(url.toString());
    }
}