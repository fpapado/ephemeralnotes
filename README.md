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

The following principles guide the project.
Each feature or change should be evaluated against them.

### Data ownership

The application should avoid storing data in a remote location.
The user notes (including time and location) should stay on the local device.
It is up to the user to export them and share them however they want.

Note that this has implications for the architecture; many server-side solutions are not possible. That fact shouls be communicated to the user.

### Accessibility

People use the web in different ways, and we should acommodate them.

The Web Content Accessibility Guidelines 2.1 ([WCAG 2.1](https://www.w3.org/TR/WCAG21/)) cover a number of criteria to consider when putting things online. We should strive for level AA, or even AAA.

In practice, this means evaluating the markup that we put on the page, validating our assumptions about interactions, and ensuring that states are communicated correctly. Where such choices are made, we should document the reasoning and share references.

### Performance

Not everyone has expensive, fast devices.
In fact, [as a trend, it appears that computing has gotten cheaper, not faster](https://infrequently.org/2017/10/can-you-afford-it-real-world-web-performance-budgets/).
A median device can still run slow if overloaded with Javascript.
We should aim to deliver the experience in the amount of JS needed, and no more.

This has implications for the choice of technology, feature set and testing.
For example, Elm allows us to have very small and perfomant bundles.
Similarly, using Web Components and ports for more specialized APIs (maps, storage persistence) allow us to use tested implementations, without rolling our own potentially heavy and unreliable ones.

### Don't give up on the user

An application that works locally can fail in many ways. We should inform the user why things failed, whether it is expected, and whether they can do anything about it (even if it means trying again later!).

For example, Geolocation can fail, data can get corrupted, the user might change the contents, or a service worker might be waiting to update. We should be honest about those possibilities, and architect the code in a way that will prompt us to communicate these to the user.

### Document why

This is partially covered by the above.
Where code is concerned, we should strive to document why a certain decision was made.

Was a certain CSS order needed to progressively enhance features? Did we elect a specific markup pattern to expose features to Assistive Technologies? Were there compromises or assumptions in any of them? These are the kind of things we should document.

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
