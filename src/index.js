import {Elm} from '../dist/js/elm.js';
import {InstallBanner} from './customElements/installBanner';
import styles from './styles/index.css';

const storageKey = 'ephemeral-store';
const app = Elm.Main.init(/*{ flags: flags }*/);

if ('customElements' in window) {
  // The install banner is only needed in Chrome > 68, so no
  // need to polyfill CEs atm. See `docs/browser_support.md`
  // for guidance.
  customElements.define('install-banner', InstallBanner);
}

//app.ports.swFromElm.subscribe()
const UpdateAvailable = {
  tag: 'UpdateAvailable',
  data: {},
};

// TEST
app.ports.swToElm.send(UpdateAvailable);

// app.ports.storeCache.subscribe(val => {
//   if (val === null) {
//     localStorage.removeItem(storageKey);
//   } else {
//     localStorage.setItem(storageKey, JSON.stringify(val));
//   }

//   // Report that the new session was stored succesfully.
//   setTimeout(() => { app.ports.onStoreChange.send(val); }, 0);
// });

// Whenever localStorage changes in another tab, report it if necessary.
// window.addEventListener("storage", event => {
//   if (event.storageArea === localStorage && event.key === storageKey) {
//     app.ports.onStoreChange.send(event.newValue);
//   }
// }, false);
