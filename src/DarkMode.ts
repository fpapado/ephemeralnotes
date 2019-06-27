export {handleSubMessage};

import * as idbKeyval from 'idb-keyval';
import {Elm} from './Main';

// Types
type Mode = 'Dark' | 'Light';

// To Elm type constructors
const ModeSet = (data: Mode) => ({
  tag: 'ModeSet',
  data,
});

// From Elm
export type FromElm = {tag: 'SetMode'; data: Mode};

/** Respond to a Store.FromElm message */
async function handleSubMessage(
  sendToElm: Elm.Main.App['ports']['darkModeToElm']['send'],
  msg: FromElm
) {
  if (!msg.tag) {
    console.error('No tag for msg', msg);
    return;
  }

  if (process.env.NODE_ENV !== 'production') {
    console.log('From Elm: ', msg);
  }

  switch (msg.tag) {
    case 'SetMode':
      setMode(msg.data);
      sendToElm(ModeSet(msg.data));
      return;

    default:
      console.warn('Unknown message: ', msg);
      return;
  }
}

// --- Internals ---

// TODO: Use idb-keyval?
function setMode(mode: Mode) {
  // First, set the mode in HTML
  const root = document.getElementsByTagName('html')[0];

  if (mode === 'Dark') {
    root.classList.add('dark-mode');
  } else {
    root.classList.remove('dark-mode');
  }

  // Then, persist the mode
  persistMode(mode);
}

function persistMode(mode: Mode) {
  idbKeyval.set('DarkMode', mode);
}
