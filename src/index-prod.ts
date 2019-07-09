/** This file is here to import an optimised Elm output.
 *  @see docs/build.md for details
 */
// @ts-ignore
import {Elm} from '../dist/js/elm.js';
import * as localTimeElement from './time-elements/local-time-element';
import * as client from './client';

function init() {
  client.runWith(Elm);

  // Define <local-time>
  localTimeElement.define();

  // Import the leaflet component dynamically, to prioritise the rest of the interface
  import(/* webpackChunkName: "leaflet-wc" */ './leaflet/leaflet-wc')
    .then(leaflet => leaflet.init())
    .catch(err => {
      console.error(err);
    });

  // Define <storage-space>
  import(/* webpackChunkName: "storage-space" */ './storage-space')
    .then(storageSpace => storageSpace.define())
    .catch(err => {
      console.error(err);
    });

  // Define <system-info>
  import(/* webpackChunkName: "system-info" */ './system-info')
    .then(systemInfo => systemInfo.define())
    .catch(err => {
      console.error(err);
    });
}

init();
