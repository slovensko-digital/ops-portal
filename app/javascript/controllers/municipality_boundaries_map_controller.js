import {Controller} from "@hotwired/stimulus"
import L from 'leaflet';

const SLOVAKIA_BOUNDS = [[47.483, 15.781], [50.032, 22.813]];

// Connects to data-controller="municipality-boundaries-map"
export default class extends Controller {
    static targets = ["map", "filter", "activeGroup", "tree", "panel", "detail"]
    static values = {url: String, detailUrl: String, selected: Object}

    connect() {
        this.map = L.map(this.mapTarget, {maxZoom: 19});
        this.layers = {};
        this.selectedId = null;
        // a shared link with a selected boundary opens its detail first, so the map fits next to the panel
        if (this.selectedValue.id) {
            this.selectedId = this.selectedValue.id;
            this.openDetail(this.selectedId);
        }
        this.map.fitBounds(this.selectedValue.bounds || SLOVAKIA_BOUNDS);

        L.tileLayer('https://a.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap',
            maxNativeZoom: 18,
            maxZoom: 19,
        }).addTo(this.map);

        // city districts lie inside their municipality, so their layer is kept on top
        this.map.createPane('municipality').style.zIndex = 400;
        this.map.createPane('district').style.zIndex = 410;

        this.map.on('zoomstart', () => this.zooming = true);
        this.map.on('zoomend', () => this.zooming = false);
        this.map.on('click', () => this.unselect());
        this.map.on('moveend', () => this.load());
        this.load({fitToSelection: !this.selectedId});
    }

    disconnect() {
        this.abortController?.abort();
        this.map.remove();
    }

    filter(event) {
        if (event.target.type === 'search') return;

        if (event.target.name === 'municipality_district_ids[]' && event.target.checked) this.filterTarget.querySelector('#kinds_district').checked = true;
        this.activeGroupTarget.disabled = !this.filterTarget.querySelector('#matched_matched').checked;

        this.treeTargets.forEach(tree => this.updateTreeSummary(tree));
        this.updateUrl();
        this.load({fitToSelection: true});
    }

    closeTree(event) {
        this.treeTargets.forEach(tree => {
            if (!tree.contains(event.target)) tree.open = false;
        });
    }

    updateTreeSummary(tree) {
        const labels = [...tree.querySelectorAll('input[type=checkbox]:checked')]
            .map(checkbox => checkbox.closest('label').querySelector('span').textContent);
        const summary = tree.querySelector('[data-tree-summary]');
        summary.textContent = labels.length ? labels.join(', ') : summary.dataset.treeSummary;
        summary.closest('summary').title = summary.textContent;
    }

    filterParams() {
        return new URLSearchParams(new FormData(this.filterTarget));
    }

    updateUrl() {
        const params = this.filterParams();
        if (this.selectedId) params.set('boundary', this.selectedId);

        const url = new URL(window.location.href);
        url.search = params.toString();
        Turbo.navigator.history.replace(url);
    }

    load({fitToSelection = false} = {}) {
        // kept until a load finishes, a newer load (e.g. after the map moved) must not drop the fit
        if (fitToSelection) this.pendingFit = true;
        this.abortController?.abort();
        this.abortController = new AbortController();

        const params = this.filterParams();
        const kinds = params.getAll('kinds[]').filter(Boolean);
        const selection = [...params.getAll('municipality_ids[]'), ...params.getAll('municipality_district_ids[]')];

        Object.entries(this.layers).forEach(([kind, layer]) => {
            if (!kinds.includes(kind)) this.map.removeLayer(layer);
        });

        const url = new URL(this.urlValue, window.location.origin);
        url.search = params.toString();
        url.searchParams.set('z', this.map.getZoom());
        // a selection is small enough to load whole, so the map can zoom to it
        if (!selection.length) url.searchParams.set('bbox', this.map.getBounds().toBBoxString());

        fetch(url, {signal: this.abortController.signal, headers: {Accept: 'application/json'}})
            .then(response => response.json())
            .then(data => {
                kinds.forEach(kind => {
                    const layer = this.layerFor(kind).addTo(this.map);
                    layer.clearLayers();
                    layer.addData(data.features.filter(feature => feature.properties.kind === kind));
                });
                this.selectedLayer()?.bringToFront();

                const fit = this.pendingFit;
                this.pendingFit = false;
                if (fit && selection.length) this.fitTo(kinds.map(kind => this.layers[kind]));
            })
            .catch(error => {
                if (error.name !== 'AbortError') throw error;
            });
    }

    fitTo(layers) {
        const bounds = L.latLngBounds([]);
        layers.forEach(layer => {
            if (layer.getLayers().length) bounds.extend(layer.getBounds());
        });
        if (!bounds.isValid()) return;

        // Leaflet ignores a zoom requested while another zoom is still animating
        const fitBounds = () => this.map.fitBounds(bounds, {padding: [20, 20]});
        this.zooming ? this.map.once('zoomend', fitBounds) : fitBounds();
    }

    // The look of a boundary, including hover and selection, comes from its classes and the CSS in the layout.
    layerFor(kind) {
        this.layers[kind] ??= L.geoJSON(null, {
            pane: kind,
            style: ({properties}) => ({
                className: [
                    'boundary', `boundary-${properties.id}`, `boundary-${kind}`,
                    properties.matched ? null : 'unmatched-boundary',
                    properties.id === this.selectedId ? 'selected-boundary' : null,
                ].filter(Boolean).join(' '),
            }),
            onEachFeature: (feature, layer) => {
                layer.bindTooltip(this.tooltipContent(feature.properties), {sticky: true});
                layer.on('click', event => {
                    L.DomEvent.stopPropagation(event);
                    feature.properties.id === this.selectedId ? this.unselect() : this.select(layer);
                });
            },
        });
        return this.layers[kind];
    }

    selectedLayer() {
        if (!this.selectedId) return null;

        return Object.values(this.layers)
            .flatMap(layer => layer.getLayers())
            .find(layer => layer.feature.properties.id === this.selectedId);
    }

    select(layer) {
        this.selectedLayer()?.getElement()?.classList.remove('selected-boundary');
        this.selectedId = layer.feature.properties.id;
        layer.getElement()?.classList.add('selected-boundary');
        layer.bringToFront();

        this.openDetail(this.selectedId);
        this.updateUrl();
    }

    openDetail(id) {
        this.detailTarget.src = this.detailUrlValue.replace(':id', id);
        this.togglePanel(true);
    }

    unselect() {
        if (!this.selectedId) return;

        this.selectedLayer()?.getElement()?.classList.remove('selected-boundary');
        this.selectedId = null;

        this.detailTarget.removeAttribute('src');
        this.detailTarget.replaceChildren();
        this.togglePanel(false);
        this.updateUrl();
    }

    togglePanel(open) {
        if (this.panelTarget.hidden !== open) return;

        this.panelTarget.hidden = !open;
        // keep the map where it is, by default Leaflet keeps the center and shifts the view by half the panel
        this.map.invalidateSize({pan: false});
    }

    tooltipContent(properties) {
        const name = properties.municipality_district_name || properties.municipality_name;
        // a text node, Leaflet would insert a string as HTML
        return document.createTextNode(name || `Nespárovaná hranica #${properties.id}`);
    }
}
