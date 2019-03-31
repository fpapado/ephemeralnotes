/** This file is here to import Elm for hot-loading during dev.
 *  @see docs/build.md for details
 */
import {Elm} from './Main.elm';
import * as client from './client.js';

function init() {
  client.runWith(Elm);
}

init();
