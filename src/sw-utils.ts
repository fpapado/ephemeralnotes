/**
    @see https://developers.google.com/web/tools/workbox/guides/advanced-recipes
*/
export function listenForWaitingSW(
  registration: ServiceWorkerRegistration | undefined,
  cb: (registration: ServiceWorkerRegistration) => void
) {
  function awaitStateChange() {
    if (registration && registration.installing) {
      registration.installing.addEventListener('statechange', function(event) {
        if (event && event.target) {
          if (((event.target as any).state as string) === 'installed') {
            cb(registration);
          }
        }
      });
    }
  }
  if (!registration) return;

  // SW is waiting to activate. Can occur if multiple clients are open and
  // one of the clients is refreshed.
  if (registration.waiting) return cb(registration);

  if (registration.installing) awaitStateChange();

  // We are currently controlled so a new SW may be found...
  // Add a listener in case a new SW is found,
  registration.addEventListener('updatefound', awaitStateChange);
}
