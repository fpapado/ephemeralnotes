/** This file is here to import Elm for hot-loading during dev.
 *  @see docs/build.md for details
 */
import {Elm} from './Main';
import * as client from './client';
import * as leaflet from './leaflet/leaflet-wc';

function init() {
  client.runWith(Elm);
  leaflet.init();
}

init();
