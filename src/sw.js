workbox.precaching.precacheAndRoute(self.__precacheManifest || []);
workbox.routing.registerNavigationRoute('/');

// Listen for postMessage(), well, mesages
addEventListener('message', messageEvent => {
  switch (messageEvent.data) {
    case 'SkipWaiting':
      return skipWaiting();
  }
});
