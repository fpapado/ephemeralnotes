# ephemeralnotes.app

Ephemeral is a progressive web app for writing down words and their translations, as you encounter them.

I made this originally when I immigrated to Finland and wanted a way to connect words with events and the world around me. I make this app in my free time.

The app works offline and all data is stored locally to your device.

![The map screen of the application, with a marker on Helsinki](docs/map.jpg)


## Features
- [X] Write down notes
- [X] Works offline
- [X] Resilient to errors
- [X] You can install it / add to home screen on most devices (including smartphones, desktops etc.)
- [X] You can always export and import data, as it's stored locally

## Development

If you want more information on the setup, [check out the docs/build.md](docs/build.md) file.

Work on a CONTRIBUTING.md document is underway :)

## PWA, Offline Data
A Progressive Web App (PWA) works offline via a Service Worker, which caches assets and scripts.

For storage, Ephemeral uses IndexedDB, which is a local, persisted database in your browser.

Service workers are scaffolded with [workbox](https://developers.google.com/web/tools/workbox/<Paste>)

[Here is an intro to PWAs, by Google](https://developers.google.com/web/progressive-web-apps/).

