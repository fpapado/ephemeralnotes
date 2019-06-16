# TODO

## Static

- [x] Build pipeline just with npm commands and some light bundling, perhaps
- [x] index.html with inlined critical CSS
- [x] Font and font loading strategy (variable fonts, font-display: swap, preload?)
  - `preload` and `variable-fonts` have some good overlap, so we are not wasting much...
- Github PR pipeline (now integration)
- Script preload
- Brotli compression and type
- namespace (filespace?) js/css assets
- postcss / autoprefixer
- remove unused Tachyons classes
- move SW state to top-level
- [x] style installBanner
- [?] inline all the CSS

## MVP

- idb-keyval and Port architecture
- Data structures
- simple viewer
- App shell

## Accessibility

- [ ] Test Focus management with screen readers, decide on timeout before focus

## Performance

- [x] Import leaflet-wc dynamically, make placholder leaflet-map with aspect-ratio

## Features

- [ ] Printable "cards" mode, with print styles and grid
- [ ] Remove "null island" default, pick something else
- [ ] Also store accuracy from Geolocation
- [ ]  Send "App is ready to use offline" notification
