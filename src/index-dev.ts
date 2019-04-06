/** This file is here to import Elm for hot-loading during dev.
 *  @see docs/build.md for details
 */
import {Elm} from './Main';
import * as client from './client';

function init() {
  client.runWith(Elm);

  // Import the leaflet component dynamically, to prioritise the rest of the interface
  import('./leaflet/leaflet-wc')
    .then(leaflet => leaflet.init())
    .catch(err => {
      console.error(err);
    });
}

init();
