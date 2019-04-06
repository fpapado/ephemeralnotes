import L from 'leaflet';

// NOTE: This plugin assumes a global 'L' being available, because it is old-school cool
// doing import '' means that side-effects can be run
// TODO: Fork the plugin and use a factory/constructor :)
import 'leaflet.markercluster';

// Grab a hashed URL reference to the leaflet css
// This is done through webpack, which knows to grab the url and bundle it
// @see webpack.donfig.js
//@ts-ignore
import styleUrl from '../styles/leaflet.css';

// Type that chidren must implement in order to get added to the layer
// Might change in the future (see note about Events below)
export type AddToLayerCb = (marker: L.Marker) => void;
export type RemoveFromLayerCb = (marker: L.Marker) => void;

const CONTAINER_ID = 'leaflet-map-container';

// Import the local leaflet styles
const styleLink = `<link rel="stylesheet" href="${styleUrl}" />`;

const template = document.createElement('template');
template.innerHTML = `
${styleLink}

<style>
  :host {
    display: block;
    max-width: 100%;
  }

  .container {
    height: 32rem;
    background-color: #ddd;
  }
</style>
<div class="container" id="${CONTAINER_ID}"></div>
`;

type ObservedAttribute = 'latitude' | 'longitude' | 'zoom';
type ReflectedAttribute = 'latitude' | 'longitude' | 'zoom';
type Property = 'latitude' | 'longitude' | 'zoom';

class LeafletMap extends HTMLElement {
  latitude?: number;
  longitude?: number;
  zoom?: number;
  private $mapContainer: HTMLDivElement;
  private observer: MutationObserver;
  private map?: L.Map | null;
  private markersLayer?: L.LayerGroup | null;
  private isConnectedForReal: boolean;

  constructor() {
    super();
    this.attachShadow({mode: 'open'});
    this.shadowRoot!.appendChild(template.content.cloneNode(true));
    this.$mapContainer = this.shadowRoot!.getElementById(
      CONTAINER_ID
    ) as HTMLDivElement;

    // Set up a mutation observer
    this.observer = new MutationObserver(
      this.childrenChangedCallback.bind(this)
    );

    this.isConnectedForReal = false;
  }

  static get observedAttributes(): ObservedAttribute[] {
    return ['latitude', 'longitude', 'zoom'];
  }

  childrenChangedCallback(mutations: MutationRecord[]) {
    mutations.forEach(mutation => {
      if (mutation.type === 'childList' && mutation.addedNodes) {
        this._updateFeaturesFor(mutation.addedNodes);
      }
    });
  }

  connectedCallback() {
    this.upgradeProperty('latitude');
    this.upgradeProperty('longitude');
    this.upgradeProperty('zoom');

    this.map = L.map(this.$mapContainer);

    L.tileLayer(
      'https://stamen-tiles.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.png',
      {
        attribution:
          'Map tiles by <a href="http://stamen.com">Stamen Design</a>, under <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a href="http://openstreetmap.org">OpenStreetMap</a>, under <a href="http://www.openstreetmap.org/copyright">ODbL</a>.',
        // id: 'stamen.toner',
        maxZoom: 13,
      }
    ).addTo(this.map);

    this.markersLayer = (L as any).markerClusterGroup();
    this.map.addLayer(this.markersLayer!);

    this.isConnectedForReal = true;
    this.setMapView();

    // Handle any children that were already parsed before this
    // element upgraded, and pass the map to them
    if (this.shadowRoot!.host.children) {
      this._updateFeaturesFor(this.shadowRoot!.host.children);
    }

    // Handle any children that are added after this element
    // is upgraded.
    // We do this because the MutationObserver will not fire if
    // the children were already parsed before the element was
    // upgraded.
    // Initialise observing
    this.observer.observe(this.shadowRoot!.host, {childList: true});
  }

  disconnectedCallback() {
    // Disconnect observer, remove leaflet
    this.observer.disconnect();
    this.map!.remove();
    this.map = null;
    this.markersLayer = null;
  }

  attributeChangedCallback(name: ObservedAttribute, oldVal: any, newVal: any) {
    this[name] = parseFloat(newVal);
    if (this.isConnectedForReal) {
      this.setMapView();
    }
  }

  // TODO: Instead of this, perhaps use events for the children to notify the parent of additions
  // I *think* that might be more composable
  private _updateFeaturesFor(nodes: NodeList | HTMLCollection) {
    if (nodes.length && this.map) {
      for (const feature of nodes) {
        // NOTE: We could make this more open, if we want to allow extensions
        if (feature.nodeName.toLowerCase() === 'leaflet-marker') {
          // Wait till after the leaflet-marker element has been upgraded
          // and had a chance to run its connectedCallback.
          customElements.whenDefined('leaflet-marker').then(_ => {
            // TS hack...
            if (!(feature as any).addToLayerCb) {
              (feature as any).addToLayerCb = (feature: L.Marker) => {
                // NOTE: Could also do this.markersLayer.addLayer(feature)
                // which one is more valid?
                feature.addTo(this.markersLayer!);
              };
              (feature as any).removeFromLayerCb = (feature: L.Marker) => {
                // NOTE: Could also do this.markersLayer.addLayer(feature)
                // which one is more valid?
                // TODO: Types are meh
                feature.removeFrom(this.markersLayer as any);
              };
            }
          });
        }
      }
    }
  }

  private setMapView() {
    if (this.latitude && this.longitude && this.zoom) {
      this.map!.setView([this.latitude, this.longitude], this.zoom);
    } else {
      // If no lat or lon provided, then show the world
      this.map!.fitWorld();
    }
  }

  private upgradeProperty(prop: Property) {
    if (this.hasOwnProperty(prop)) {
      let value = this[prop];
      delete this[prop];
      this[prop] = value;
    } else {
      const attr = this.getAttribute(prop);
      if (attr) {
        this[prop] = parseFloat(attr);
      }
    }
  }
}

export const define = () =>
  window.customElements.define('leaflet-map', LeafletMap);
