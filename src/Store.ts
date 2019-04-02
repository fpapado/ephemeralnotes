export {handleSubMessage};

import {openDB, DBSchema} from 'idb';
import nanoid from 'nanoid';
import {Elm} from './Main';
import {Result, Result_Ok, Result_Error} from './Geolocation';

// FromElm
// TODO: UpdateEntry Entry

// Store <-> Elm

// ToElm

type EntryToElm = EntryV1 & {schema_version: number};
type PartialEntryFromElm = Omit<EntryV1, 'id'> & {schema_version: number};

const GotEntries = (data: EntryToElm[]) => ({
  tag: 'GotEntries',
  data,
});

const GotEntry = (data: Result<string, EntryToElm>) => ({
  tag: 'GotEntry',
  data,
});

export type FromElm =
  | {tag: 'StoreEntry'; data: PartialEntryFromElm}
  | {tag: 'GetEntries'};

/** Respond to a Store.FromElm message */
function handleSubMessage(
  sendToElm: Elm.Main.App['ports']['storeToElm']['send'],
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
    case 'StoreEntry':
      storeAndGetEntry(msg.data)
        .then(entry => {
          if (entry) {
            const entryToElm = {...entry, schema_version: 1};
            sendToElm(GotEntry(Result_Ok(entryToElm)));
          }
        })
        .catch(err => {
          console.error(err);
          sendToElm(GotEntry(Result_Error(err.toString)));
        });
      return;

    case 'GetEntries':
      getEntries().then(entries => {
        const entriesToElm = entries.map(entry => ({
          ...entry,
          schema_version: 1,
        }));
        sendToElm(GotEntries(entriesToElm));
      });
      return;

    default:
      console.warn('Unknown message: ', msg);
      return;
  }
}

// --- Internals ---

const ENTRY_DB_NAME = 'ephemeral-db-entries';
const ENTRY_DB_VERSION = 1;
const ENTRY_STORE_NAME = 'entries';

enum Index {
  Time = 'time',
}

type EntryV1 = {
  id: string;
  front: string;
  time: number;
  location: {
    lat: number;
    lon: number;
  };
};

interface DBV1 extends DBSchema {
  [ENTRY_STORE_NAME]: {
    value: EntryV1;
    key: string;
    indexes: {[Index.Time]: number};
  };
}

async function storeAndGetEntry(entry: PartialEntryFromElm) {
  const key = await storeEntry(entry);
  return getEntry(key);
}

async function getEntry(key: string) {
  const db = await openEntryDB();
  return db.get(ENTRY_STORE_NAME, key);
}

async function getEntries() {
  const db = await openEntryDB();
  return db.getAllFromIndex(ENTRY_STORE_NAME, Index.Time);
}

async function storeEntry(entry: PartialEntryFromElm) {
  const db = await openEntryDB();
  // Generate a random id
  // TODO: Find the difference between this and autoIncrement
  const id = nanoid();
  const newEntry = {...entry, id};
  return db.add(ENTRY_STORE_NAME, newEntry);
}

async function openEntryDB() {
  return openDB<DBV1>(ENTRY_DB_NAME, ENTRY_DB_VERSION, {
    upgrade(db, oldVersion, newVersion) {
      if (oldVersion < 1) {
        const store = db.createObjectStore(ENTRY_STORE_NAME, {
          // The 'id' property of the object will be the key
          keyPath: 'id',
          // If not explicitly set, create a value by auto incrementing
          autoIncrement: true,
        });

        // Create an index on the 'time' property
        store.createIndex(Index.Time, 'time');
      }
    },
  });
}

// UTIL
type Omit<Obj, Key> = Pick<Obj, Exclude<keyof Obj, Key>>;