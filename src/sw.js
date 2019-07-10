import * as precaching from 'workbox-precaching';
import * as routing from 'workbox-routing';
import * as strategies from 'workbox-strategies';
import * as expiration from 'workbox-expiration';

precaching.precacheAndRoute(self.__WB_MANIFEST);
workbox.routing.registerNavigationRoute(
  // Assuming '/index.html' has been precached,
  // look up its corresponding cache key.
  workbox.precaching.getCacheKeyForURL('/index.html')
);

// Listen for postMessage(), well, mesages
// One of interest is 'SkipWaiting', to instruct the SW to skip waiting directly
// It is used to power the "reload for latest version" popup
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

// Cache webfonts at runtime
routing.registerRoute(
  /\.(?:woff|woff2)$/,
  new strategies.CacheFirst({
    cacheName: 'fonts',
    plugins: [
      new expiration.Plugin({
        maxAgeSeconds: 60 * 60 * 24 * 365, // 1 year
        maxEntries: 30,
        purgeOnQuotaError: true, // allow font caches to be purged to free space
      }),
    ],
  })
);
