export {Mode, handleSubMessage, setInitialDarkMode};

import * as idbKeyval from 'idb-keyval';
import {Elm} from './Main';

// Types and constatns
type Mode = typeof DARK | typeof LIGHT;

const DARK = 'Dark';
const LIGHT = 'Light';
const DARK_CLASS = 'dark-mode';
const STORE_KEY = 'dark-mode';
const MQ_DARK = '(prefers-color-scheme: dark)';
const MQ_LIGHT_OR_NONE = [
  '(prefers-color-scheme: light)',
  '(prefers-color-scheme: no-preference)',
];

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
  setDocumentClass(mode);

  // Then, persist the mode
  persistUserModePreference(mode);
}

function setDocumentClass(mode: Mode) {
  const root = document.documentElement;

  if (mode === DARK) {
    root.classList.add(DARK_CLASS);
  } else {
    root.classList.remove(DARK_CLASS);
  }
}

function persistUserModePreference(mode: Mode) {
  idbKeyval.set(STORE_KEY, mode);
}

async function getUserModePreference() {
  return idbKeyval.get<string | undefined>(STORE_KEY);
}

async function setInitialDarkMode() {
  const initialDarkMode = await getInitialDarkMode();
  setDocumentClass(initialDarkMode);
  return initialDarkMode;
}

/** Get the initial dark mode state, by combining sources of data:
 *  - The user's persisted preference (takes precedence)
 *  - The matchMedia media query
 *    - If light or no preference, then light
 *    - If preference for dark, then dark
 *
 *  TODO:
 *  Additionally, set a listener for matchMedia:
 *    - If the user has not declared a preference, then set the mode in HTML, and send ModeSet to elm
 */
async function getInitialDarkMode(): Promise<Mode> {
  const existingPreference = await getUserModePreference();

  // Has the user specified a preference?
  if (
    existingPreference !== undefined &&
    [DARK, LIGHT].includes(existingPreference)
  ) {
    return existingPreference as Mode;
  }

  // Does the browser support native `prefers-color-scheme`?
  const supportsPrefersColorScheme =
    window.matchMedia('(prefers-color-scheme)').media !== 'not all';

  // If it does, then select based on `prefers-color-scheme`
  if (supportsPrefersColorScheme) {
    if (
      window.matchMedia(MQ_LIGHT_OR_NONE[0]).matches ||
      window.matchMedia(MQ_LIGHT_OR_NONE[1]).matches
    ) {
      return LIGHT;
    } else if (window.matchMedia(MQ_DARK).matches) {
      return DARK;
    }
  }

  // Otherwise, return LIGHT
  return LIGHT;
}
