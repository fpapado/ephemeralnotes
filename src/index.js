import {Elm} from '../dist/js/elm.js';
import {InstallBanner} from './customElements/installBanner';
import {listenForWaitingSW} from './sw-utils.js';
import styles from './styles/index.css';

// Start Elm app
const app = Elm.Main.init(/*{ flags: flags }*/);

// Install banner
if ('customElements' in window) {
  // The install banner is only needed in Chrome > 68, so no
  // need to polyfill CEs atm. See `docs/browser_support.md`
  // for guidance.
  customElements.define('install-banner', InstallBanner);
}

// PORTS

// TO ELM
const UpdateAvailable = {
  tag: 'UpdateAvailable',
  data: {},
};

// Service Worker refresh
// Get registration
navigator.serviceWorker.getRegistration(reg =>
  // Prompt user to refresh the service worker, when there is one waiting
  listenForWaitingSW(reg, app.ports.swToElm.send(UpdateAvailable))
);

// Reload once the new Service Worker starts activating
let refreshing;
navigator.serviceWorker.addEventListener('controllerchange', () => {
  if (refreshing) return;
  refreshing = true;
  window.location.reload();
});

// FROM ELM
app.ports.swFromElm.subscribe(msg => {
  if (!msg.tag) {
    console.error('No tag for msg', msg);
    return;
  }

  switch (msg.tag) {
    // Post a message to the SW to skip waiting
    case 'UpdateAccepted':
      navigator.serviceWorker.getRegistration(reg =>
        reg.waiting.postMessage('SkipWaiting')
      );
      return;
    // Do nothing on deferred update
    case 'UpdateDeferred':
      return;
  }
});
