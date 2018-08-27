importScripts("/third_party/workbox/workbox-sw.js");

workbox.setConfig({
  modulePathPrefix: "/third_party/workbox/"
});

workbox.precaching.precacheAndRoute(self.__precacheManifest || []);
workbox.routing.registerNavigationRoute("/");
