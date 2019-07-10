workbox.precaching.precacheAndRoute(self.__WB_MANIFEST);
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

// Cache webfonts at runtime
workbox.routing.registerRoute(
  /\.(?:woff|woff2)$/,
  new workbox.strategies.CacheFirst({
    cacheName: 'fonts',
    plugins: [
      new workbox.expiration.Plugin({
        maxAgeSeconds: 60 * 60 * 24 * 365, // 1 year
        maxEntries: 30,
        purgeOnQuotaError: true, // allow font caches to be purged to free space
      }),
    ],
  })
);
