workbox.precaching.precacheAndRoute(self.__precacheManifest || []);
workbox.routing.registerNavigationRoute('/');

// Listen for postMessage(), well, mesages
addEventListener('message', msgEvent => {
  switch (msgEvent.data) {
    case 'SkipWaiting':
      return skipWaiting();
  }
});
