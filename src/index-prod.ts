/** This file is here to import an optimised Elm output.
 *  @see docs/build.md for details
 */
// @ts-ignore
import {Elm} from '../dist/js/elm.js';
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
