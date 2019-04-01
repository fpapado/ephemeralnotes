/** This file is here to import an optimised Elm output.
 *  @see docs/build.md for details
 */
// @ts-ignore
import {Elm} from '../dist/js/elm.js';
import * as client from './client';

function init() {
  client.runWith(Elm);
}

init();
