// @ts-ignore
import './styles/index.css';
import {listenForWaitingSW} from './sw-utils';
import {Elm} from './Main/index';
import {getLocation, Location, LocationError} from './Geolocation';
import * as Store from './Store';
import * as DarkMode from './DarkMode';
import {Result} from './Core';

export async function runWith(Elm_: typeof Elm) {
  // Get the initial flags for starting the Elm app
  const initialDarkMode = await DarkMode.setInitialDarkMode();

  // Start Elm app
  const app = Elm_.Main.init({flags: {initialDarkMode}});

  // PORTS

  // TODO: Move these to ServiceWorker.ts
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
    let deferredPrompt: BeforeInstallPromptEvent | null;
    window.addEventListener('beforeinstallprompt', e => {
      console.log('Before install prompt', e);

      // Prevent Chrome 67 and earlier from automatically showing the prompt
      e.preventDefault();

      // Stash the event so it can be triggered later.
      deferredPrompt = e as BeforeInstallPromptEvent;

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
    let preventDevToolsReloadLoop: boolean;
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      // Ensure refresh is only called once.
      // This works around a bug in "force update on reload".
      if (preventDevToolsReloadLoop) return;
      preventDevToolsReloadLoop = true;
      console.log('SW controller loaded, will reload window.');
      window.location.reload();
    });

    // SW FROM ELM
    type SWFromElm =
      | {tag: 'UpdateAccepted'}
      | {tag: 'UpdateDeferred'}
      | {tag: 'InstallPromptAccepted'}
      | {tag: 'InstallPromptDeferred'};

    app.ports.swFromElm.subscribe(unkMsg => {
      let msg = unkMsg as SWFromElm;

      if (!msg.tag) {
        console.warn('No tag for msg', msg);
        return;
      }

      if (process.env.NODE_ENV !== 'production') {
        console.log('From Elm: ', msg);
      }

      switch (msg.tag) {
        // Post a message to the waiting SW to skip waiting
        case 'UpdateAccepted':
          navigator.serviceWorker.getRegistration().then(registration => {
            if (registration && registration.waiting) {
              registration.waiting.postMessage('SkipWaiting');
            }
          });
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
        case 'InstallPromptDeferred':
          return;

        default:
          console.warn('Unknown message: ', msg);
          return;
      }
    });
  }

  // GEOLOCATION <-> ELM
  // TODO: Move these to Geolocation.ts
  const GotLocationMsg = (data: Result<LocationError, Location>) => ({
    tag: 'GotLocation',
    data,
  });

  type GeolocationFromElm = {tag: 'GetLocation'};

  app.ports.geolocationFromElm.subscribe(unkMsg => {
    let msg = unkMsg as GeolocationFromElm;
    if (!msg.tag) {
      console.warn('No tag for msg', msg);
      return;
    }

    if (process.env.NODE_ENV !== 'production') {
      console.log('From Elm: ', msg);
    }

    switch (msg.tag) {
      // Post a message to the waiting SW to skip waiting
      case 'GetLocation':
        getLocation(data => {
          app.ports.geolocationToElm.send(GotLocationMsg(data));
        });
        return;

      default:
        console.warn('Unknown message: ', msg);
        return;
    }
  });

  // Store <-> Elm
  app.ports.storeFromElm.subscribe(unkMsg => {
    let msg = unkMsg as Store.FromElm;
    Store.handleSubMessage(app.ports.storeToElm.send, msg).catch(err => {
      console.error(
        'Unhandled error from Store.handleSubMessage. This should be impossible, but here we are.',
        err
      );
    });
  });

  // DarkMode <-> Elm
  app.ports.darkModeFromElm.subscribe(unkMsg => {
    let msg = unkMsg as DarkMode.FromElm;
    DarkMode.handleSubMessage(app.ports.darkModeToElm.send, msg);
  });
}
