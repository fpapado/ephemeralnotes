/** This file is here to import an optimised Elm output.
 *  @see docs/build.md for details
 */
import {Elm} from '../dist/js/elm.js';
import * as client from './client.js';

function init() {
  client.runWith(Elm);
}

init();
