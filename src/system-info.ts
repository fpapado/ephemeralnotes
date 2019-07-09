import {getStyleResult} from './leaflet/util';

const styleText = `
:host {
  display: block;
  max-width: 100%;
}
ul {
  padding-left: 1em;
  margin: 0;
}
ul > * + * {
  margin-top: 0.5rem;
}
@supports (font-variation-settings: normal) {
  b {
    font-variation-settings: 'wght' 700;
  }
}
`;

// Same as the other styles in this application
const styleResult = getStyleResult(styleText);

const CONTAINER_ID = 'container';

const template = document.createElement('template');

template.innerHTML = `
${styleResult.text ? `<style>${styleResult.text}</style>` : ''}
<div id=${CONTAINER_ID}>
</div>
`;

type InfoTuple = [string, string | number | boolean];

class SytemInfo extends HTMLElement {
  private $container: HTMLDivElement;
  constructor() {
    super();
    const shadowRoot = this.attachShadow({mode: 'open'});
    shadowRoot.appendChild(template.content.cloneNode(true));

    // Adopt stylesheet, if supported
    if (styleResult.sheet) {
      (shadowRoot as any).adoptedStyleSheets = [styleResult.sheet];
    }

    // Add refs to elements
    this.$container = shadowRoot.getElementById(CONTAINER_ID) as HTMLDivElement;
  }

  connectedCallback() {
    // Only actually parse the stylesheet when the first instance is connected.
    if (styleResult.sheet && styleResult.sheet.cssRules.length === 0) {
      (styleResult.sheet as any).replaceSync(styleText);
    }

    const info = this._getInfo();
    this._setInfo(info);
  }

  private _getInfo(): InfoTuple[] {
    const supportsStorage = 'storage' in navigator;
    const UA = window.navigator.userAgent;
    const standaloneMode = window.matchMedia('(display-mode: standalone)')
      .matches
      ? 'yes'
      : 'no';
    const screenWidth = window.innerWidth;
    const screenHeight = window.innerHeight;
    const supportsCustomElements = 'customElements' in window;

    return [
      ['Version', NOW_GITHUB_COMMIT_SHA],
      ['Standalone Mode', standaloneMode],
      ['Screen Width', screenWidth],
      ['Screen Height', screenHeight],
      ['Supports custom elements', supportsCustomElements],
      ['Supports StorageManager', supportsStorage],
      ['UA', UA],
    ];
  }

  private _setInfo(info: InfoTuple[]) {
    this.$container.innerHTML = `
        <ul>
            ${info
              .map(
                ([term, data]) =>
                  `<li><b class="term">${term}:</b> ${data}</li>`
              )
              .join('\n')}
        </ul>
    `;
  }

  disconnectedCallback() {}
}

export const define = () => {
  window.customElements.define('system-info', SytemInfo);
};
