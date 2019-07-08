import prettyBytes from 'pretty-bytes';
import {getStyleResult} from './leaflet/util';

const styleText = `
:host {
  display: block;
  max-width: 100%;
}
.container {
  font-size: 1.15rem;
}
.svg-container {
  display: none;
  margin-top: 0.5rem;
}
.bg {
  fill: #ccc;
}
.data {
  fill: var(--color-accent);
}
.markers {
  fill: #001f3f;
}
.percents {
  fill: var(--color-text);
  font-size: 3rem;
}
`;

// Import the local styles
// We use the ConstructableStyleSheet where supported
// The ConstructableStyleSheet proposal allows sharing of styles
// between different roots (including document and shadow roots).
// This is better than using <style>, because the sheets can be
// cached, shared, parsed once etc. This means that multiple instances
// of the same component will only need to incur the parsing cost once!
const styleResult = getStyleResult(styleText);

const CAPTION_ID = 'caption';
const SVG_ID = 'svg-container';
const DATA_ID = 'data';

const template = document.createElement('template');

// NOTE: Since the SVG has a textual alternative already (the caption),
// we set aria-hidden="true" to hide it from Assistive Technologies
template.innerHTML = `
${styleResult.text ? `<style>${styleResult.text}</style>` : ''}
<div class="container">
    <div id="${CAPTION_ID}"></div>
    <svg id="${SVG_ID}" class="svg-container" width="100%" height="65px" viewBox="0 0 1132 130" aria-hidden="true" focusable="false">
    <g class="bars">
        <rect class="bg" width="100%" height="50"></rect>
        <rect id="${DATA_ID}" class="data" height="50"></rect>
    </g>
    <g class="markers">
        <rect x="0%" y="0" width="2px" height="70"></rect>
        <rect x="25%" y="0" width="2px" height="70"></rect>
        <rect x="50%" y="0" width="2px" height="70"></rect>
        <rect x="75%" y="0" width="2px" height="70"></rect>
        <rect text-anchor="" x="1130" y="0" width="2px" height="70"></rect>
    </g>
    <g text-anchor="middle" class="percents">
        <text text-anchor="start" x="0" y="120">0%</text>
        <text x="25%" y="120">25%</text>
        <text x="50%" y="120">50%</text>
        <text x="75%" y="120">75%</text>
        <text text-anchor="end" x="100%" y="120">100%</text>
    </g>
    </svg>
</div>
`;

class StorageSpace extends HTMLElement {
  private $caption: HTMLDivElement;
  private $data: SVGRectElement;
  private $svg: SVGElement;
  constructor() {
    super();
    const shadowRoot = this.attachShadow({mode: 'open'});
    shadowRoot.appendChild(template.content.cloneNode(true));

    // Adopt stylesheet, if supported
    if (styleResult.sheet) {
      (shadowRoot as any).adoptedStyleSheets = [styleResult.sheet];
    }

    // Add refs to elements
    this.$caption = shadowRoot.getElementById(CAPTION_ID) as HTMLDivElement;
    this.$data = (shadowRoot.getElementById(DATA_ID) as any) as SVGRectElement;
    this.$svg = (shadowRoot.getElementById(SVG_ID) as any) as SVGElement;
  }

  connectedCallback() {
    // Only actually parse the stylesheet when the first instance is connected.
    if (styleResult.sheet && styleResult.sheet.cssRules.length === 0) {
      (styleResult.sheet as any).replaceSync(styleText);
    }

    this._setQuota();
  }

  private async _setQuota() {
    if ('storage' in navigator && 'estimate' in navigator.storage) {
      const {usage, quota} = await navigator.storage.estimate();
      if (usage && quota) {
        const percentUsed = Math.round((usage / quota) * 100);
        const formattedUsage = prettyBytes(usage, {locale: true});
        const formattedQuota = prettyBytes(quota, {locale: true});

        const details = `${formattedUsage} out of ${formattedQuota} used (${percentUsed}%)`;

        this.$caption.innerText = details;
        this.$data.style.width = `${percentUsed}%`;
        this.$svg.style.display = 'block';
      }
    } else {
      this.$caption.innerText =
        'Sorry, this browser does not support estimates of data usage.';
    }
  }

  disconnectedCallback() {}
}

export const define = () => {
  window.customElements.define('storage-space', StorageSpace);
};
