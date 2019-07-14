# Ephemeral

(Live version: https://ephemeralnotes.app)

Ephemeral is a progressive web app for writing down words and their translations, as you encounter them.

I made this originally when I immigrated to Finland and wanted a way to connect words with events and the world around me. I make this app in my free time.

The app works offline and all data is stored locally to your device.

![The map screen of the application, with a marker on Helsinki.](docs/map.jpg)

## Table of Contents

1. [Features](#features)
2. [Principles](#principles)
3. [Development](#development)
4. [Production](#production)
5. [List of Tech Used](#list-of-tech-used)
6. [Architecture](#architecture)
7. [Contributing](#contributing)
8. [Code of Conduct](#code-of-conduct)
9. [Thanks and Credits](#thanks-and-credits)
10. [License](#license)

## Features

- Can capture notes, time, and (optionally) location
- Works offline
- Resilient to errors
- You can install it / add to home screen on most devices (including smartphones, desktops etc.)
- You can always export and import data, as it's stored locally

## Principles

## Development

If you want more information on the setup, [check out the docs/build.md](docs/build.md) file.

Work on a CONTRIBUTING.md document is underway :)

## Production

## List of Tech Used

If you are interested in contributing, you will see many of the following terms and libraries.
We introduce them here to establish a common starting point.

A Progressive Web App (PWA) works offline via a Service Worker, which caches assets and scripts. A PWA can be installed locally, on most devices. [Here is an intro to PWAs, by Google](https://developers.google.com/web/progressive-web-apps/).

Service Workers are a rather low-level API. To make them more declarative, and to manage the asset invalidation when they change, we use [Workbox](https://developers.google.com/web/tools/workbox/).

For storage, Ephemeral uses [IndexedDB](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API), which is a local, persisted database in the browser.
IndexedDB is built-in to browsers, and exposes a number of low-level interfaces.
To make that more manageable, we use [idb](https://github.com/jakearchibald/idb), which is a library that wraps IndexedDB in promises, and tries to expose errors more consistently.

## Architecture

## Contributing

If you are interested in contributing, please [consult CONTRIBUTING.md](/CONTRIBUTING.md) for how to do so. That document covers topics such as opening issues, creating PRs, running tests, as well as the principles and code of conduct.

## Code of Conduct

## Thanks and Credits

## License

Mozilla Public License Version 2.0
