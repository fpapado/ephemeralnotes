# Browser Support
Browser support and syntax is driven by the features we use:
- IndexedDB
- Service Workers
- JS-only, app shell in HTML

The reason for being in JS only is that we want the data to be local to the device.
Server-side support is a non-goal, because that would mean keeping people's data.
Only the minimal server-side (app shell + handoff) is supported.

In order for the application to work, technically only IndexedDB is needed.
Service workers are nice-to-have in terms of serving the assets and application regardless of connection.

The baseline for IndexedDB is IE 10 or IE 11, with some fiddly support.

## ES version
The code is not currently ES5, but it is only some glue code that could change.
In general, transpiling classes can be verbose, and prior to Babel 7 error-prone.

If there is a need, we can set up transpilation to ES5, and keep serving ES2015 to modern browsers.
This would likely complicate the loading and preloading strategies (fiddling with type="module" and "nomodule" to differentiate).

In addition, polyfills should be considered to get a complete ES5 environment.
A good differential polyfill service places more ephasis on having a server.

Within Service Workers, ES2015 can be used freely, since the compatibility is an overlap.

One notable exception when considering "modern browsers" is that "async-await" is not supported everywhere.
I personally do not use it anyway, but good to document that :)

With the above in mind, it seems that supporting IE11 would take a while.
This is my hobby project, and I would rather put that energy in making sure the site is performant and accessible for users on other browsers.

## Custom Elements and Shadow DOM
Custom Elements are used to make dealing with Service worker APIs a bit nicer in Elm.
They are not needed per se, but the alternative would be a number of extra state and callbacks that the app need not know about.

The polyfill for Shadow DOM seems heavier than just for Custom Elements.
CEs could be polyfilled, if need be. A map might bring that need up at some point.

Custom Elements are good for passing CustomEvent(s) and state to the Elm view functions.
Shadow DOM- connected CEs achieve that, in addition to allowing complex markup inside of them.
Using complex markup in plain CEs with Elm might surface issues with the VDOM diffing overriding the contents.
This is a bit unfortunate for some use cases.

Whenever a CE/ShadowDOM component is used, we should audit the environment it is used in.
For example, the `InstallBanner` component is used to handle the Chrome-only `beforeinstallevent` interaction for installation.
Thus, using CEs/ShadowDOM there is ok.
