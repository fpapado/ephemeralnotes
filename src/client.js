import './styles/index.css';
import {listenForWaitingSW} from './sw-utils';
import {getLocation} from './Geolocation.js';
import * as Store from './Store.js';

export function runWith(Elm) {
  // Start Elm app
  const app = Elm.Main.init({});

  // PORTS

  // TO ELM
  const UpdateAvailable = {
    tag: 'UpdateAvailable',
    data: {},
  };

  const BeforeInstallPrompt = {
    tag: 'BeforeInstallPrompt',
    data: {},
  };

  // Service Worker <-> Elm
  // TO ELM
  if ('serviceWorker' in navigator) {
    // Chrome App Install Banner
    let deferredPrompt;
    window.addEventListener('beforeinstallprompt', e => {
      console.log('Before install prompt', e);

      // Prevent Chrome 67 and earlier from automatically showing the prompt
      e.preventDefault();

      // Stash the event so it can be triggered later.
      deferredPrompt = e;

      // Notify the user
      app.ports.swToElm.send(BeforeInstallPrompt);
    });

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

      if (process.env.NODE_ENV !== 'production') {
        console.log('From Elm: ', msg);
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
        case 'InstallPromptAccepted': {
          if (!deferredPrompt) return;

          // Show the Chrome prompt
          deferredPrompt.prompt();

          // Wait for the user to respond to the prompt
          deferredPrompt.userChoice.then(choiceResult => {
            if (choiceResult.outcome === 'accepted') {
              console.log('User accepted the A2HS prompt');
            } else {
              console.log('User dismissed the A2HS prompt');
            }
            deferredPrompt = null;
          });
          return;
        }
        case 'InstallPromptDefered':
          return;
      }
    });
  }

  // GEOLOCATION <-> ELM
  const GotLocationMsg = data => ({
    tag: 'GotLocation',
    data,
  });

  app.ports.geolocationFromElm.subscribe(msg => {
    if (!msg.tag) {
      console.error('No tag for msg', msg);
      return;
    }

    if (process.env.NODE_ENV !== 'production') {
      console.log('From Elm: ', msg);
    }

    switch (msg.tag) {
      // Post a message to the waiting SW to skip waiting
      case 'GetLocation':
        getLocation(data => {
          console.log(GotLocationMsg(data));
          app.ports.geolocationToElm.send(GotLocationMsg(data));
        });
        return;
    }
  });

  // Store <-> Elm
  app.ports.storeFromElm.subscribe(msg => {
    Store.handleSubMessage(app.ports.storeToElm.send, msg);
  });
}
