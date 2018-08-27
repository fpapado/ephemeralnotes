import { Elm } from "../dist/js/elm.js";

const storageKey = "ephemeral-store";
const app = Elm.Main.init(/*{ flags: flags }*/);

// app.ports.storeCache.subscribe(val => {
//   if (val === null) {
//     localStorage.removeItem(storageKey);
//   } else {
//     localStorage.setItem(storageKey, JSON.stringify(val));
//   }

//   // Report that the new session was stored succesfully.
//   setTimeout(() => { app.ports.onStoreChange.send(val); }, 0);
// });

// Whenever localStorage changes in another tab, report it if necessary.
// window.addEventListener("storage", event => {
//   if (event.storageArea === localStorage && event.key === storageKey) {
//     app.ports.onStoreChange.send(event.newValue);
//   }
// }, false);
