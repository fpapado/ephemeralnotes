export {handleSubMessage};

import {openDB} from 'idb';

// FromElm
// type FromElm = {tag: 'StoreEntry', data: Entry} | {tag: 'GetEntries'}
// TODO: UpdateEntry Entry

// Store <-> Elm

// ToElm

const GotEntries = data => ({
  tag: 'GotEntries',
  data,
});

const SavedEntryOk = data => ({
  tag: 'SavedEntryOk',
  data,
});

const SavedEntryErr = data => ({
  tag: 'SavedEntryErr',
  data,
});

/** Respond to a Store.FromElm message */
function handleSubMessage(sendToElm, msg) {
  if (!msg.tag) {
    console.error('No tag for msg', msg);
    return;
  }

  if (process.env.NODE_ENV !== 'production') {
    console.log('From Elm: ', msg);
  }

  switch (msg.tag) {
    case 'StoreEntry':
      storeEntry(msg.data)
        .then(data => {
          sendToElm(SavedEntryOk(data));
        })
        .catch(err => {
          console.error(err);
          sendToElm(SavedEntryErr());
        });
      return;

    case 'GetEntries':
      getEntries().then(data => {
        sendToElm(GotEntries(data));
      });
      return;
  }
}

// --- Internals ---

const ENTRY_DB_NAME = 'ephemeral-db-entries';
const ENTRY_DB_VERSION = 1;
const ENTRY_STORE_NAME = 'entries';

const Index = {
  Time: 'time',
};

// interface DBV1 extends DBSchema {
//   [ENTRY_STORE_NAME]: {
//     value: {
//       id: string,
//       front: string,
//       time: number,
//       location: {
//         lat: number,
//         lon: number
//      }
//     },
//     key: string,
//     indexes: { [Index[Time]]: number },
//   }
// }

async function getEntries() {
  const db = await openEntryDB();
  return db.getAllFromIndex(ENTRY_STORE_NAME, Index.Time);
}

async function openEntryDB() {
  return openDB(ENTRY_DB_NAME, ENTRY_DB_VERSION, {
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
