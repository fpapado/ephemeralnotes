import L from 'leaflet';

// Import references to leaflet's markers

//@ts-ignore
import marker from 'leaflet/dist/images/marker-icon.png';
//@ts-ignore
import marker2x from 'leaflet/dist/images/marker-icon-2x.png';
//@ts-ignore
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

// Hack to make it work with webpack-provided URLs
// @see https://github.com/PaulLeCam/react-leaflet/issues/255

//@ts-ignore
delete L.Icon.Default.prototype._getIconUrl;

console.log({marker, marker2x, markerShadow});

const template = document.createElement('template');
template.innerHTML = `
<style>
    :host {
        display: none;
    }
</style>
`;

// TODO: Consider reflecting the properties to attributes here
type ObservedAttribute = 'latitude' | 'longitude';
type ReflectedAttribute = 'latitude' | 'longitude';
type Property = 'latitude' | 'longitude' | 'leafletMap';

class LeafletPin extends HTMLElement {
  latitude?: number;
  longitude?: number;
  private _leafletMap?: L.Map | null;
  private feature?: L.Marker;

  constructor() {
    super();
    this.attachShadow({mode: 'open'});
    this.shadowRoot!.appendChild(template.content.cloneNode(true));
  }

  static get observedAttributes(): ObservedAttribute[] {
    return ['latitude', 'longitude'];
  }

  get leafletMap() {
    return this._leafletMap;
  }

  set leafletMap(value) {
    this._leafletMap = value;
    this.onMapChanged();
  }

  connectedCallback() {
    // The caller might have set properties before our script runs
    // We handle this by "upgrading" properties
    // @see https://developers.google.com/web/fundamentals/web-components/best-practices#lazy-properties
    this.upgradeProperty('latitude');
    this.upgradeProperty('longitude');
    this.upgradeProperty('leafletMap');
    this.mapReady();
  }

  disconnectedCallback() {
    // Remove the feature from the map
    if (this.feature && this._leafletMap) {
      this.feature.removeFrom(this._leafletMap);
    }
    this._leafletMap = null;
  }

  attributeChangedCallback(name: ObservedAttribute, oldVal: any, newVal: any) {
    this[name] = parseFloat(newVal);
    this.updatePosition();
  }

  onMapChanged() {
    this.mapReady();
  }

  mapReady() {
    if (this.latitude && this.longitude && this._leafletMap) {
      this.feature = L.marker([this.latitude, this.longitude], {
        icon: new L.Icon.Default({
          // Point to local markers
          iconRetinaUrl: marker2x,
          iconUrl: marker,
          shadowUrl: markerShadow,
        }),
      });
      this.feature.addTo(this._leafletMap);

      // TODO: Set up mutations for this, because the content can change independently!
      this.contentChanged();
    }
  }

  contentChanged() {
    if (this.feature) {
      this.feature.bindPopup(this.innerHTML);
    }
  }

  updatePosition() {
    if (this.feature && this.latitude && this.longitude) {
      this.feature.setLatLng(L.latLng(this.latitude, this.longitude));
    }
  }

  upgradeProperty(prop: Property) {
    if (this.hasOwnProperty(prop)) {
      let value = this[prop];
      delete this[prop];
      this[prop] = value;
    }
  }
}

export const define = () =>
  window.customElements.define('leaflet-marker', LeafletPin);
