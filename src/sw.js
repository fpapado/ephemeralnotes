workbox.precaching.precacheAndRoute(self.__precacheManifest || []);
workbox.routing.registerNavigationRoute('/');

// Listen for postMessage(), well, mesages
self.addEventListener('message', messageEvent => {
  if (!messageEvent.data) {
    return;
  }

  switch (messageEvent.data) {
    case 'SkipWaiting':
      self.skipWaiting();
      break;
    default:
      // NOOP
      break;
  }
});
