/** This file is here to import Elm for hot-loading during dev.
 *  @see docs/build.md for details
 */
import {Elm} from './Main.elm';
import {runClient} from './client.js';

runClient(Elm);
