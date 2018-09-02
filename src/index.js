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

// Service Worker <-> Elm
if ('serviceWorker' in navigator) {
  // Service Worker refresh
  // Get registration
  navigator.serviceWorker.getRegistration().then(registration => {
    console.log('Got registration', registration);
    // Prompt user to refresh the service worker, when there is one waiting
    listenForWaitingSW(registration, () => {
      console.log('Found waiting SW');
      app.ports.swToElm.send(UpdateAvailable);
    });
  });

  // Reload once the new Service Worker starts activating
  // When the user asks to refresh the UI, we'll need to reload the window
  let preventDevToolsReloadLoop;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    // Ensure refresh is only called once.
    // This works around a bug in "force update on reload".
    if (preventDevToolsReloadLoop) return;
    preventDevToolsReloadLoop = true;
    console.log('SW controller loaded, will reload window.');
    window.location.reload();
  });

  // FROM ELM
  app.ports.swFromElm.subscribe(msg => {
    if (!msg.tag) {
      console.error('No tag for msg', msg);
      return;
    }

    switch (msg.tag) {
      // Post a message to the waiting SW to skip waiting
      case 'UpdateAccepted':
        navigator.serviceWorker
          .getRegistration()
          .then(registration =>
            registration.waiting.postMessage('SkipWaiting')
          );
        return;
      // Do nothing on deferred update
      case 'UpdateDeferred':
        return;
    }
  });
}
