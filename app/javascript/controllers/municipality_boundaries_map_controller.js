import {Controller} from "@hotwired/stimulus"
import L from 'leaflet';

// Connects to data-controller="municipality-boundaries-map"
export default class extends Controller {
    static targets = ["map", "filter", "activeGroup", "tree", "panel", "detail"]
    static values = {url: String, detailUrl: String, selected: Object}

    connect() {
        this.map = L.map(this.mapTarget, {maxZoom: 19});
        this.layers = {};
        this.selected = null;
        // a shared link with a selected boundary opens its detail first, so the map fits next to the panel
        if (this.selectedValue.id) {
            this.selected = {kind: this.selectedValue.kind, id: this.selectedValue.id};
            this.openDetail(this.selected.id);
        }
        this.map.fitBounds(this.selectedValue.bounds || [[47.483, 15.781], [50.032, 22.813]]);

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
        // a boundary redrawn under a resting pointer can miss its mouseout, so leaving the map clears the hover
        this.map.on('mouseout', () => this.hovered && this.unhover(this.hovered));
        this.map.on('moveend', () => this.load());
        this.load({fitToSelection: !this.selected});
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

    // A group with nothing checked is sent as an empty value ("kinds[]="), because a missing group
    // means all of its options on the server. A disabled group is left out.
    filterParams() {
        const params = new URLSearchParams();
        for (const [name, value] of new FormData(this.filterTarget)) {
            if (value !== '') params.append(name, value);
        }
        this.filterTarget.querySelectorAll('fieldset:not([disabled]) input[type=checkbox][name$="[]"]').forEach(({name}) => {
            if (!params.has(name)) params.append(name, '');
        });
        return params;
    }

    updateUrl() {
        const params = this.filterParams();
        if (this.selected) params.set('boundary', this.selected.id);

        const url = new URL(window.location.href);
        url.search = params.toString();
        Turbo.navigator.history.replace(url);
    }

    load({fitToSelection = false} = {}) {
        // kept until a load finishes, a newer load (e.g. after the map moved) must not drop the fit
        if (fitToSelection) this.pendingFit = true;
        this.abortController?.abort();
        this.abortController = new AbortController();
        const signal = this.abortController.signal;
        const params = this.filterParams();
        const kinds = params.getAll('kinds[]').filter(Boolean);
        params.delete('kinds[]');
        const selection = [...params.getAll('municipality_ids[]'), ...params.getAll('municipality_district_ids[]')];

        Object.entries(this.layers).forEach(([kind, layer]) => {
            if (!kinds.includes(kind)) this.map.removeLayer(layer);
        });

        const requests = kinds.map(kind => {
            const layer = this.layerFor(kind).addTo(this.map);

            const url = new URL(this.urlValue, window.location.origin);
            url.search = params.toString();
            url.searchParams.set('kinds[]', kind);
            url.searchParams.set('z', this.map.getZoom());
            // a selection is small enough to load whole, so the map can zoom to it
            if (!selection.length) url.searchParams.set('bbox', this.map.getBounds().toBBoxString());

            return fetch(url, {signal, headers: {Accept: 'application/json'}})
                .then(response => response.json())
                .then(data => {
                    layer.clearLayers();
                    layer.addData(data);
                    this.selectedLayer()?.bringToFront();
                });
        });

        Promise.all(requests)
            .then(() => {
                const fit = this.pendingFit;
                this.pendingFit = false;
                if (!fit || !selection.length) return;

                const bounds = L.latLngBounds([]);
                kinds.forEach(kind => {
                    if (this.layers[kind].getLayers().length) bounds.extend(this.layers[kind].getBounds());
                });
                if (!bounds.isValid()) return;

                // Leaflet ignores a zoom requested while another zoom is still animating
                const fitBounds = () => this.map.fitBounds(bounds, {padding: [20, 20]});
                this.zooming ? this.map.once('zoomend', fitBounds) : fitBounds();
            })
            .catch(error => {
                if (error.name !== 'AbortError') throw error;
            });
    }

    layerFor(kind) {
        this.layers[kind] ??= L.geoJSON(null, {
            pane: kind,
            style: feature => {
                // the colors come from the boundary-<kind> and unmatched-boundary classes in the layout
                const className = `boundary-${feature.properties.id} boundary-${kind}${feature.properties.matched ? '' : ' unmatched-boundary'}`;
                const style = {weight: 1.5, fillOpacity: 0.1, className};
                return this.isSelected(feature) ? {...style, weight: 4, fillOpacity: 0.45} : style;
            },
            onEachFeature: (feature, layer) => {
                layer.bindTooltip(this.tooltipContent(feature.properties), {sticky: true});
                layer.on('mouseover', () => {
                    this.hovered = layer;
                    layer.setStyle({weight: 4, fillOpacity: Math.max(0.35, layer.options.fillOpacity)});
                    layer.bringToFront();
                });
                layer.on('mouseout', () => this.unhover(layer));
                layer.on('click', event => {
                    L.DomEvent.stopPropagation(event);
                    this.isSelected(feature) ? this.unselect() : this.select(layer);
                });
            },
        });
        return this.layers[kind];
    }

    unhover(layer) {
        if (this.hovered === layer) this.hovered = null;
        layer.closeTooltip();
        layer.feature && this.layers[layer.feature.properties.kind].resetStyle(layer);
        this.selectedLayer()?.bringToFront();
    }

    isSelected(feature) {
        return this.selected?.kind === feature.properties.kind && this.selected?.id === feature.properties.id;
    }

    selectedLayer() {
        if (!this.selected) return null;

        return this.layers[this.selected.kind]?.getLayers().find(layer => this.isSelected(layer.feature));
    }

    select(layer) {
        const {properties} = layer.feature;
        const previous = this.selectedLayer();
        this.selected = {kind: properties.kind, id: properties.id};
        if (previous) this.layers[previous.feature.properties.kind].resetStyle(previous);

        this.layers[properties.kind].resetStyle(layer);
        layer.bringToFront();

        this.openDetail(properties.id);
        this.updateUrl();
    }

    openDetail(id) {
        this.detailTarget.src = this.detailUrlValue.replace(':id', id);
        this.togglePanel(true);
    }

    unselect() {
        if (!this.selected) return;

        const layer = this.selectedLayer();
        this.selected = null;
        if (layer) this.layers[layer.feature.properties.kind].resetStyle(layer);

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
