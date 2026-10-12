import {Controller} from "@hotwired/stimulus"
import L from 'leaflet';

const escape = text => Object.assign(document.createElement('div'), {textContent: text}).innerHTML;
const cssColor = name => getComputedStyle(document.documentElement).getPropertyValue(`--color-${name}`).trim();

// Connects to data-controller="municipality-boundaries-map"
export default class extends Controller {
    static targets = ["map", "filter", "tree", "panel", "detail"]
    static values = {url: String, detailUrl: String, selected: Object}

    connect() {
        this.map = L.map(this.mapTarget, {maxZoom: 19});
        this.map.fitBounds(this.selectedValue.bounds || [[47.483, 15.781], [50.032, 22.813]]);

        L.tileLayer('https://a.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap',
            maxNativeZoom: 18,
            maxZoom: 19,
        }).addTo(this.map);

        this.syncTreeParents();
        this.treeTargets.forEach(tree => this.updateTreeSummary(tree));
        this.layers = {};
        this.selected = null;
        // a shared link with a selected boundary opens its detail, the map is already zoomed to it
        if (this.selectedValue.id) {
            this.selected = {kind: this.selectedValue.kind, id: this.selectedValue.id};
            this.openDetail(this.selected.id);
        }
        this.map.on('click', () => this.unselect());
        this.map.on('moveend', () => this.load());
        this.load({fitToSelection: !this.selected});
    }

    disconnect() {
        this.abortController?.abort();
        this.map.remove();
    }

    filter(event) {
        if (event.target.type === 'search') return;

        if (event.target.dataset.treeParent) this.childCheckboxes(event.target).forEach(child => child.checked = event.target.checked);
        this.syncTreeParents();
        this.treeTargets.forEach(tree => this.updateTreeSummary(tree));
        this.updateUrl();
        this.load({fitToSelection: true});
    }

    // keeps the address bar in sync with the filter and the selected boundary, so the page can be shared
    updateUrl() {
        const params = new URLSearchParams();
        for (const [name, value] of new FormData(this.filterTarget)) {
            if (value !== '') params.append(name, value);
        }
        if (!params.has('boundaries[]')) params.append('boundaries[]', '');
        if (this.selected) params.set('boundary', this.selected.id);

        const url = new URL(window.location.href);
        url.search = params.toString();
        Turbo.navigator.history.replace(url);
    }

    closeTree(event) {
        this.treeTargets.forEach(tree => {
            if (!tree.contains(event.target)) tree.open = false;
        });
    }

    // a parent checkbox only toggles its children, it is not a filter value by itself
    childCheckboxes(parent) {
        return [...parent.closest('li').querySelectorAll(':scope > ul input[type=checkbox]:not([data-tree-parent])')];
    }

    syncTreeParents() {
        this.element.querySelectorAll('[data-tree-parent]').forEach(parent => {
            const checked = this.childCheckboxes(parent).map(child => child.checked);
            parent.checked = checked.every(Boolean);
            parent.indeterminate = !parent.checked && checked.some(Boolean);
        });
    }

    // Lists the topmost fully checked nodes, prefixed with the labels of their parent nodes,
    // e.g. "Obce, Mestské časti › Spárované › Aktívne".
    updateTreeSummary(tree) {
        const label = checkbox => checkbox.closest('label').querySelector('span').textContent;
        const parents = checkbox => {
            const result = [];
            for (let li = checkbox.closest('li').parentElement.closest('li'); li && tree.contains(li); li = li.parentElement.closest('li')) {
                const parent = li.querySelector(':scope > label [data-tree-parent]');
                if (parent) result.unshift(parent);
            }
            return result;
        };

        const labels = [...tree.querySelectorAll('input[type=checkbox]:checked')]
            .filter(checkbox => !parents(checkbox).some(parent => parent.checked))
            .map(checkbox => [...parents(checkbox), checkbox].map(label).join(' › '));
        const summary = tree.querySelector('[data-tree-summary]');
        summary.textContent = labels.length ? labels.join(', ') : summary.dataset.treeSummary || 'Všetky';
        summary.closest('summary').title = summary.textContent;
    }

    load({fitToSelection = false} = {}) {
        this.abortController?.abort();
        this.abortController = new AbortController();
        const signal = this.abortController.signal;
        const filter = new FormData(this.filterTarget);
        const statusesByKind = {};
        filter.getAll('boundaries[]').forEach(value => {
            const [kind, status] = value.split(':');
            (statusesByKind[kind] ??= []).push(status);
        });
        const kinds = Object.keys(statusesByKind);
        const selection = [...filter.getAll('municipality_ids[]'), ...filter.getAll('municipality_district_ids[]')];

        Object.entries(this.layers).forEach(([kind, layer]) => {
            if (!kinds.includes(kind)) this.map.removeLayer(layer);
        });

        const requests = kinds.map(kind => {
            const layer = this.layerFor(kind).addTo(this.map);

            const url = new URL(this.urlValue, window.location.origin);
            url.searchParams.set('kind', kind);
            statusesByKind[kind].forEach(status => url.searchParams.append('statuses[]', status));
            url.searchParams.set('z', this.map.getZoom());
            filter.getAll('municipality_ids[]').forEach(id => url.searchParams.append('municipality_ids[]', id));
            filter.getAll('municipality_district_ids[]').forEach(id => url.searchParams.append('municipality_district_ids[]', id));
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
                if (!fitToSelection || !selection.length) return;

                const bounds = L.latLngBounds([]);
                kinds.forEach(kind => {
                    if (this.layers[kind].getLayers().length) bounds.extend(this.layers[kind].getBounds());
                });
                if (bounds.isValid()) this.map.fitBounds(bounds, {padding: [20, 20]});
            })
            .catch(error => {
                if (error.name !== 'AbortError') throw error;
            });
    }

    layerFor(kind) {
        this.layers[kind] ??= L.geoJSON(null, {
            style: feature => {
                const color = cssColor(feature.properties.matched ? kind : 'unmatched');
                const style = {color, weight: 1.5, fillColor: color, fillOpacity: 0.1, className: `boundary-${feature.properties.id}`};
                return this.isSelected(feature) ? {...style, weight: 4, fillOpacity: 0.45} : style;
            },
            onEachFeature: (feature, layer) => {
                layer.bindTooltip(this.tooltipContent(feature.properties), {sticky: true});
                layer.on('mouseover', () => {
                    layer.setStyle({weight: 4, fillOpacity: Math.max(0.35, layer.options.fillOpacity)});
                    layer.bringToFront();
                });
                layer.on('mouseout', () => {
                    this.layers[kind].resetStyle(layer);
                    this.selectedLayer()?.bringToFront();
                });
                layer.on('click', event => {
                    L.DomEvent.stopPropagation(event);
                    this.isSelected(feature) ? this.unselect() : this.select(layer);
                });
            },
        });
        return this.layers[kind];
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
        this.map.invalidateSize();
    }

    tooltipContent(properties) {
        const name = properties.municipality_district_name || properties.municipality_name;
        return name ? escape(name) : `Nespárovaná hranica #${properties.id}`;
    }
}
