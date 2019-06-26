export {handleSubMessage};

import {openDB, DBSchema} from 'idb';
import nanoid from 'nanoid';
import {Elm} from './Main';
import {Result, Result_Ok, Result_Error} from './Geolocation';

// FromElm
// TODO: UpdateEntry Entry

// Store <-> Elm

// To Elm

type EntryToElm = EntryV1 & {schema_version: number};

// To Elm type constructors

const GotEntries = (data: EntryToElm[]) => ({
  tag: 'GotEntries',
  data,
});

const GotBatchImportedEntries = (
  // TODO: Write a more accurate union type for IDBRequest
  data: Result<DOMException['name'], number>
) => ({
  tag: 'GotBatchImportedEntries',
  data,
});

const GotEntry = (data: Result<string, EntryToElm>) => ({
  tag: 'GotEntry',
  data,
});

// From Elm
type PartialEntryFromElm = Omit<EntryV1, 'id'> & {schema_version: number};

export type FromElm =
  | {tag: 'StoreEntry'; data: PartialEntryFromElm}
  | {tag: 'StoreBatchImportedEntries'; data: Array<EntryV1>}
  | {tag: 'GetEntries'};

/** Respond to a Store.FromElm message */
async function handleSubMessage(
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
      storeAndGetPartialEntry(msg.data)
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

    case 'StoreBatchImportedEntries':
      // TODO: Should we be wrapping all the ports in try/catch? :thinking:
      try {
        const importNum = await storeBatchEntries(msg.data);

        // Immediately inform Elm that we imported entries OK
        sendToElm(GotBatchImportedEntries(Result_Ok(importNum)));

        // Additionally, get all the entries and send them to Elm
        getEntries().then(entries => {
          const entriesToElm = entries.map(entry => ({
            ...entry,
            schema_version: 1,
          }));
          sendToElm(GotEntries(entriesToElm));
        });
      } catch (err) {
        console.error(
          'Error in StoreBatchImportedEntries:',
          err && err instanceof DOMException ? err.name : 'UnaccountedError'
        );
        // Inform Elm that an error happened
        sendToElm(
          GotBatchImportedEntries(
            Result_Error(err ? err.name : 'UnaccountedError')
          )
        );
      }
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

async function storeAndGetPartialEntry(entry: PartialEntryFromElm) {
  const key = await storePartialEntry(entry);
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

async function storePartialEntry(entry: PartialEntryFromElm) {
  const db = await openEntryDB();
  // Generate a random id
  // TODO: Find the difference between this and autoIncrement
  const id = nanoid();
  const newEntry = {...entry, id};
  return db.add(ENTRY_STORE_NAME, newEntry);
}

async function storeBatchEntries(entries: Array<EntryV1>) {
  const db = await openEntryDB();

  console.log('Will add batch entries', entries);

  // Add all entries in a single transaction
  const tx = db.transaction('entries', 'readwrite');

  // TODO: This will overwrite items with the same id
  // Perhaps we should have an "overwrite same items" checkbox?
  for (const entry of entries) {
    // NOTE: It is important to await here, to propagate the error
    await tx.store.put(entry);
  }
  await tx.done;
  return entries.length;
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
