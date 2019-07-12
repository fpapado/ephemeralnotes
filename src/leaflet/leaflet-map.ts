import L, {control} from 'leaflet';

// NOTE: Leaflet plugins assume a global 'L' being available.
// `import ''` means that side-effects can be run, and attach to L.
import 'leaflet.markercluster';
import 'leaflet.featuregroup.subgroup';

// This is done through webpack, where we use postcss to bundle the CSS
// and lift the raw text in the module graph.
// @see webpack.donfig.js
//@ts-ignore
import leafletStyleText from '../styles/leaflet.css';
import {getStyleResult} from './util';

const styleText = `
:host {
  display: block;
  max-width: 100%;
}

.container {
  height: 32rem;
  background-color: var(--leaflet-map-bg) !important;
  flex-grow: 1;
  contain: layout paint;
}

${leafletStyleText}
`;

// TODO: Use the lazy init version with connectedCallback

// Import the local leaflet styles
// We use the ConstructableStyleSheet where supported
// The ConstructableStyleSheet proposal allows sharing of styles
// between different roots (including document and shadow roots).
// This is better than using <style>, because the sheets can be
// cached, shared, parsed once etc. This means that multiple instances
// of the same component will only need to incur the parsing cost once!
const styleResult = getStyleResult(styleText);

const CONTAINER_ID = 'leaflet-map-container';

const template = document.createElement('template');

template.innerHTML = `
${styleResult.text ? `<style>${styleResult.text}</style>` : ''}
<div class="container" id="${CONTAINER_ID}"></div>
`;

// Type that chidren must implement in order to get added to the layer
// Might change in the future (see note about Events below)
export type AddToLayerCb = (marker: L.Marker) => void;
export type RemoveFromLayerCb = (marker: L.Marker) => void;

type ObservedAttribute =
  | 'defaultLatitude'
  | 'defaultLongitude'
  | 'defaultZoom'
  | 'theme';
type ReflectedAttribute =
  | 'defaultLatitude'
  | 'defaultLongitude'
  | 'defaultZoom';
type Property =
  | 'defaultLatitude'
  | 'defaultLongitude'
  | 'defaultZoom'
  | 'theme';

type Theme = 'dark' | 'light';

class LeafletMap extends HTMLElement {
  defaultLatitude?: number;
  defaultLongitude?: number;
  defaultZoom?: number;
  theme?: Theme;
  private $mapContainer: HTMLDivElement;
  private observer: MutationObserver;
  private map?: L.Map | null;
  private tileLayer?: L.TileLayer | null;
  private markersLayerGroup?: L.LayerGroup | null;
  private markersFeatureGroup?: L.SubGroup | null;
  private isConnectedForReal = false;
  private hasSetInitialView = false;

  constructor() {
    super();
    this.attachShadow({mode: 'open'});
    this.shadowRoot!.appendChild(template.content.cloneNode(true));

    // Adopt stylesheet, if supported
    if (styleResult.sheet) {
      (this.shadowRoot as any).adoptedStyleSheets = [styleResult.sheet];
    }

    this.$mapContainer = this.shadowRoot!.getElementById(
      CONTAINER_ID
    ) as HTMLDivElement;

    // Set up a mutation observer
    // We need this to observe changes to the children list
    this.observer = new MutationObserver(
      this.childrenChangedCallback.bind(this)
    );

    // Bind methods
    this.setInitialViewOnce = this.setInitialViewOnce.bind(this);
    this.setMapView = this.setMapView.bind(this);
    this._updateFeaturesFor = this._updateFeaturesFor.bind(this);
  }

  static get observedAttributes(): ObservedAttribute[] {
    return ['defaultLatitude', 'defaultLongitude', 'defaultZoom'];
  }

  childrenChangedCallback(mutations: MutationRecord[]) {
    mutations.forEach(mutation => {
      if (mutation.type === 'childList' && mutation.addedNodes) {
        this._updateFeaturesFor(mutation.addedNodes);
      }
    });
    // If we have not set the initial view already, then do so
    // This helps us batch the view setting after we know the list of children!
    // NOTE: There is a race condition here (intentional).
    // We either set the view from the agregate or children, or
    // we set it to fit world
    this.setInitialViewOnce();
  }

  connectedCallback() {
    this.upgradeProperty('defaultLatitude');
    this.upgradeProperty('defaultLongitude');
    this.upgradeProperty('defaultZoom');
    this.upgradeProperty('theme');

    // Only actually parse the stylesheet when the first instance is connected.
    if (styleResult.sheet && styleResult.sheet.cssRules.length === 0) {
      (styleResult.sheet as any).replaceSync(styleText);
    }

    this.map = L.map(this.$mapContainer, {
      bounceAtZoomLimits: true,
      zoomControl: false,
    });
    this.map.addControl(control.zoom({position: 'bottomright'}));
    this.tileLayer = L.tileLayer(getTileUrl(this.theme), {
      attribution:
        'Map tiles by <a href="http://stamen.com">Stamen Design</a>, under <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a href="http://openstreetmap.org">OpenStreetMap</a>, under <a href="http://www.openstreetmap.org/copyright">ODbL</a>.',
      // id: 'stamen.toner',
      maxZoom: 17,
    });

    this.tileLayer.addTo(this.map);

    this.markersLayerGroup = L.markerClusterGroup();
    this.markersFeatureGroup = L.featureGroup.subGroup(this.markersLayerGroup);

    this.markersLayerGroup!.addTo(this.map!);
    this.markersFeatureGroup!.addTo(this.map!);

    this.isConnectedForReal = true;

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

    this.setInitialViewOnce();

    // Set this so that the map gets re-computed with the "real" height after adding to the DOM
    // Otherwise, it is assumed to be the container height of 32em.
    // This is kinda hacky, but it works :)
    // setTimeout(() => {
    // this.map!.invalidateSize();
    // });
  }

  disconnectedCallback() {
    // Disconnect observer, remove leaflet
    this.observer.disconnect();
    this.map!.remove();
    this.map = null;
    this.markersFeatureGroup = null;
    this.markersLayerGroup = null;
  }

  attributeChangedCallback(name: ObservedAttribute, oldVal: any, newVal: any) {
    if (name === 'theme') {
      if (this.tileLayer) {
        this.tileLayer.setUrl(getTileUrl(newVal));
      }
    }
    if (
      name === 'defaultLatitude' ||
      name === 'defaultLongitude' ||
      name === 'defaultZoom'
    ) {
      this[name] = parseFloat(newVal);
      if (this.isConnectedForReal) {
        this.setMapView();
      }
    }
  }

  // TODO: Instead of this, perhaps use events for the children to notify the parent of additions
  // I *think* that might be more composable
  private _updateFeaturesFor(nodes: NodeList | HTMLCollection) {
    if (nodes.length && this.map) {
      for (const feature of nodes) {
        // NOTE: We could make this more open, if we want to allow extensions
        if (feature.nodeName.toLowerCase() === 'leaflet-marker') {
          // Wait until after the leaflet-marker element has been upgraded
          // and had a chance to run its connectedCallback.
          customElements.whenDefined('leaflet-marker').then(_ => {
            // TS hack...
            if (!(feature as any).addToLayerCb) {
              (feature as any).addToLayerCb = (feature: L.Marker) => {
                feature.addTo(this.markersFeatureGroup!);
              };
              (feature as any).removeFromLayerCb = (feature: L.Marker) => {
                if (this.markersFeatureGroup) {
                  this.markersFeatureGroup!.removeLayer(feature);
                }
              };
            }
          });
        }
      }
    }
  }

  private setInitialViewOnce() {
    if (!this.hasSetInitialView) {
      this.setMapView();
      this.hasSetInitialView = true;
    }
  }

  private setMapView() {
    // If we have features, fit the map around them
    console.count('setMapView');
    if (
      this.markersFeatureGroup &&
      this.markersFeatureGroup.getLayers().length !== 0
    ) {
      // console.log('Will fit bounds');
      this.map!.fitBounds(this.markersFeatureGroup!.getBounds(), {maxZoom: 12});
    }
    // Otherwise, set to the defined lat,lng
    else if (
      this.map &&
      this.defaultLatitude !== undefined &&
      this.defaultLongitude !== undefined &&
      this.defaultZoom !== undefined
    ) {
      // console.log('Will fit lat/long');
      this.map.setView(
        [this.defaultLatitude, this.defaultLongitude],
        this.defaultZoom
      );
    }
    // Finally, if no default lat or lon provided, then show the world
    else if (this.map) {
      // console.log('Will fit world');
      this.map!.fitWorld();
    }
  }

  private upgradeProperty(prop: Property) {
    if (this.hasOwnProperty(prop)) {
      let value = this[prop];
      delete this[prop];
      // FIXME: this is hellish
      this[prop] = value as any;
    } else {
      const attr = this.getAttribute(prop);
      if (
        prop === 'defaultLatitude' ||
        prop === 'defaultLongitude' ||
        prop === 'defaultZoom'
      ) {
        if (attr !== null) {
          this[prop] = parseFloat(attr);
        }
      } else {
        this[prop] = attr as any;
      }
    }
  }
}

export const define = () => {
  window.customElements.define('leaflet-map', LeafletMap);
};

function getTileUrl(theme?: Theme) {
  if (theme === 'dark') {
    return 'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png';
  } else {
    return 'https://stamen-tiles.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.png';
  }
}
