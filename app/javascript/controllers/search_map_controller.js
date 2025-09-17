import {Controller} from "@hotwired/stimulus"
import L from 'leaflet';

export default class extends Controller {
    static targets = ["map"]
    static values = {geoJsonUrl: String}

    connect() {
        const map = L.map(this.mapTarget, {dragging: !L.Browser.mobile}).setView([48.1478, 17.1072], 10);
        let geoJsonLayer;
        let isInitialLoad = true;

        L.tileLayer('https://a.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap'
        }).addTo(map);

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
                                // Use circle marker for single items or count <= 1
                                const marker = L.circleMarker(latlng, {
                                    color: '#ff4761',
                                    fillColor: '#ff4761',
                                    fillOpacity: 0.3,
                                    radius: 5
                                });
                                marker.on('mouseover', function () {
                                    this.setStyle({
                                        radius: 5,
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
                                        radius: 5
                                    });
                                });
                                return marker;
                            }
                        },

                        onEachFeature: function (feature, layer) {
                            if (feature.properties.count === 0) {
                            } else if (feature.properties.count === 1) {
                                const popupContent = `
                                <div class="map-popup">
                                    <div class="title">${feature.properties.title}</div>
                                    <div class="location">${feature.properties.address}</div>
                                    <div class="date">${feature.properties.created_at}</div>
                                </div>
                            `;
                                layer.bindPopup(popupContent);
                                layer.on('mouseover', function () {
                                    this.openPopup();
                                });

                                layer.on('mouseout', function () {
                                    this.closePopup();
                                });

                                layer.on('click', function () {
                                    window.location.href = feature.properties.url;
                                });
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
                            padding: [20, 20]
                        });
                        isInitialLoad = false;
                    }
                });
        };

        map.on('zoomend', loadGeoJson);
        map.on('moveend', loadGeoJson);
        loadGeoJson();
    }
}