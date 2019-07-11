export {handleSubMessage};

import {openDB, DBSchema} from 'idb';
import nanoid from 'nanoid';
import {Elm} from './Main';
import {Result, Result_Ok, Result_Error} from './Core';
import * as Persistence from './Store/Persistence';

// FromElm
// TODO: UpdateEntry Entry

// Store <-> Elm

// To Elm

type EntryToElm = EntryV1 & {schema_version: number};

/**
 * A representation of IndexedDB's DOMException error names,
 * as well as an extra 'UnaccountedError'
 * @see <https://developer.mozilla.org/en-US/docs/Web/API/IDBRequest/error>
 */
type RequestError =
  | 'AbortError'
  | 'ConstraintError'
  | 'QuotaExceededError'
  | 'UnknownError'
  | 'VersionError'
  // This one means it's on us!
  | 'UnaccountedError';

const knownRequestErrors: Array<RequestError> = [
  'AbortError',
  'ConstraintError',
  'QuotaExceededError',
  'UnknownError',
  'VersionError',
];

function requestErrorFromUnknown(err: unknown): RequestError {
  if (
    err &&
    err instanceof DOMException &&
    knownRequestErrors.includes(err.name as any)
  ) {
    return err.name as RequestError;
  } else {
    return 'UnaccountedError';
  }
}

// To Elm type constructors

const GotEntries = (data: EntryToElm[]) => ({
  tag: 'GotEntries',
  data,
});

const GotBatchImportedEntries = (data: Result<RequestError, number>) => ({
  tag: 'GotBatchImportedEntries',
  data,
});

const GotEntry = (data: Result<RequestError, EntryToElm>) => ({
  tag: 'GotEntry',
  data,
});

const GotPersistence = (data: Persistence.Persistence) => ({
  tag: 'GotPersistence',
  data,
});

// From Elm
type PartialEntryFromElm = Omit<EntryV1, 'id'> & {schema_version: number};

export type FromElm =
  | {tag: 'StoreEntry'; data: PartialEntryFromElm}
  | {tag: 'StoreBatchImportedEntries'; data: Array<EntryV1>}
  | {tag: 'GetEntries'}
  | {tag: 'CheckPersistenceWithoutPrompt'}
  | {tag: 'RequestPersistence'};

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
          const reqErr = requestErrorFromUnknown(err);
          console.error('Error in storeAndGetPartialEntry', reqErr);
          // Inform Elm that an error happened
          sendToElm(GotEntry(Result_Error(reqErr)));
        });
      return;

    case 'GetEntries':
      // TODO: Handle error case here
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
      // NOTE: This can throw, so we try/catch to normalize, isntead of splitting
      // .catch and catch {}
      // https://github.com/jakearchibald/idb/#promises--throwing
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
        const reqErr = requestErrorFromUnknown(err);
        console.error('Error in StoreBatchImportedEntries', reqErr);
        // Inform Elm that an error happened
        sendToElm(GotBatchImportedEntries(Result_Error(reqErr)));
      }
      return;

    case 'CheckPersistenceWithoutPrompt':
      const persistence = await Persistence.tryPersistWithoutPromptingUser();
      sendToElm(GotPersistence(persistence));
      return;

    case 'RequestPersistence':
      const persistence_ = await Persistence.tryPersistWithPrompt();
      sendToElm(GotPersistence(persistence_));
      return;

    default:
      assertUnreachable(msg);
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
  // TODO: Try/catch, error, Result
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

/** Used with TS to assert that switch statements are exhaustive. */
function assertUnreachable(x: never): never;
function assertUnreachable(x: string) {
  console.warn('Unknown message: ', x);
}
