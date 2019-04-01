// WARNING: Do not manually modify this file. It was generated using:
// https://github.com/dillonkearns/elm-typescript-interop
// Type definitions for Elm ports

export namespace Elm {
  namespace Main {
    export interface App {
      ports: {
        swFromElm: {
          subscribe(callback: (data: unknown) => void): void;
        };
        swToElm: {
          send(data: any): void;
        };
        geolocationFromElm: {
          subscribe(callback: (data: unknown) => void): void;
        };
        geolocationToElm: {
          send(data: any): void;
        };
        storeFromElm: {
          subscribe(callback: (data: unknown) => void): void;
        };
        storeToElm: {
          send(data: any): void;
        };
      };
    }
    export function init(options: {
      node?: HTMLElement | null;
      flags: null;
    }): Elm.Main.App;
  }
}
