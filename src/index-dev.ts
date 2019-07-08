/** This file is here to import Elm for hot-loading during dev.
 *  @see docs/build.md for details
 */
import {Elm} from './Main';
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

  // Define <persistent-storage-indicator>
  import(
    /* webpackChunkName: "persistent-storage-indicator" */ './persistent-storage-indicator'
  )
    .then(persistentStorage => persistentStorage.define())
    .catch(err => {
      console.error(err);
    });
}

init();
