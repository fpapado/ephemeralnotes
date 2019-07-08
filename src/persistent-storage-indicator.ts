import {getStyleResult} from './leaflet/util';
import {stat} from 'fs';

const styleText = `
:host {
  display: block;
  max-width: 100%;
}
.container {
  font-size: 1.15rem;
}
`;

const styleResult = getStyleResult(styleText);

const CONTAINER_ID = 'container';

const template = document.createElement('template');

template.innerHTML = `
${styleResult.text ? `<style>${styleResult.text}</style>` : ''}
<p id=${CONTAINER_ID} class="container">
</p>
`;

/**
 * Component that, when connected, check for storage peristence.
 * Has five view states:
 *  - Persisted: The storage is already persistent, so we let the user know.
 *  - ShouldPrompt: The storage *could* be persisted if we prompted the user, upon interaction.
 *      We show a light warning message, and a button to do so.
 *  - Unsupported: Persisting storage is not supported, and we let the user know.
 *  - Denied: The user or UA has denied the prompt in the past.
 *  - PersistenceFailed (rare): We tried to persist but failed; internal error.
 *
 * Persisted storage is tricky! It might require a permission, which might be automatically granted
 * by the user agent. For example, Chrome might provide it if the app is installed, while Firefox might always prompt.
 * It is also possible that persistence is not supported, or that persistence is supported but
 * the Permissions API is not! In some cases, thus, we should pick a time to prompt the user,
 * ideally with an explanation as to why. In other cases, we might not ever be able to persist,
 * or even automatically be able to. Fun times :D
 *
 * The Storage Standard is short and sweet, and outlines these concerns:
 * @see https://storage.spec.whatwg.org/
 */
class PersistentStorageIndicator extends HTMLElement {
  private $container: HTMLParagraphElement;
  constructor() {
    super();
    const shadowRoot = this.attachShadow({mode: 'open'});
    shadowRoot.appendChild(template.content.cloneNode(true));

    // Adopt stylesheet, if supported
    if (styleResult.sheet) {
      (shadowRoot as any).adoptedStyleSheets = [styleResult.sheet];
    }

    // Add refs to elements
    this.$container = shadowRoot.getElementById(
      CONTAINER_ID
    ) as HTMLParagraphElement;

    // Bind methods
    this._setContentInitial = this._setContentInitial.bind(this);
    this._promptAndSetContent = this._promptAndSetContent.bind(this);
    this._setContent = this._setContent.bind(this);
  }

  connectedCallback() {
    // Only actually parse the stylesheet when the first instance is connected.
    if (styleResult.sheet && styleResult.sheet.cssRules.length === 0) {
      (styleResult.sheet as any).replaceSync(styleText);
    }

    this._setContentInitial();
  }

  private async _setContentInitial() {
    const state = await tryPersistWithoutPromptingUser();
    const text = getStateText(state);
    this._setContent(text);
    if (state === State.Prompt) {
      const button = document.createElement('button');
      button.innerText = 'Give storage permission';
      button.addEventListener('click', this._promptAndSetContent);
      this.$container.appendChild(button);
    }
  }

  // TODO: PromptAndSetContent(), button addEventListener('click', this._promptAndSetContent)
  private async _promptAndSetContent() {
    const persisted = await navigator.storage.persist();
    if (persisted === true) {
      this._setContent(getStateText(State.Persisted));
    } else {
      this._setContent(getStateText(State.Denied));
    }
  }

  private _setContent(text: string) {
    this.$container.innerText = text;
  }

  disconnectedCallback() {}
}

enum State {
  'Never',
  'Prompt',
  'Persisted',
  'FailedToPersist',
  'Denied',
}

/** Try to persist storage without ever prompting user.
  @returns {Promise<"never"|"prompt"|"persisted">}
    - "never" In case persisting is not ever possible. Caller don't bother
        asking user for permission.
    - "prompt" In case persisting would be possible if prompting user first.
    - "persisted" In case this call successfully silently persisted the storage,
        or if it was already persisted.
    - "failed-to-persist" Persistence is supported, but it failed for some reason
    - "denied" The user or UA has denied the Persistence Permission
  @see https://dexie.org/docs/StorageManager
*/
async function tryPersistWithoutPromptingUser(): Promise<State> {
  if (!navigator.storage || !navigator.storage.persisted) {
    // Storage or storage.persisted is not supported; could never succeed
    return State.Never;
  }
  let persisted = await navigator.storage.persisted();
  if (persisted === true) {
    // Already persisted previously
    return State.Persisted;
  }
  if (!navigator.permissions || !navigator.permissions.query) {
    // The permissions API is not available, so we must prompt directly
    // It MAY be successful to prompt. We don't know.
    return State.Prompt;
  }
  // We have the permissions API, so we can query it
  const permission = await navigator.permissions.query({
    name: 'persistent-storage',
  });
  // If the permission has been granted (either by the user or automatically by the user agent)
  // Then try to persist the storage
  if (permission.state === 'granted') {
    persisted = await navigator.storage.persist();
    if (persisted) {
      return State.Persisted;
    } else {
      return State.FailedToPersist;
    }
  }
  // If the Permission API tells us to prompt, well, we prompt!
  else if (permission.state === 'prompt') {
    return State.Prompt;
  }
  // If the Permission API tells us it's denied, then inform that
  else if (permission.state === 'denied') {
    return State.Denied;
  }
  // If all else fails, it is not possible to persist
  return State.Never;
}

function getStateText(state: State) {
  switch (state) {
    case State.Never:
      return 'This browser might clear entries, if storage space is running low. It unlikely, but could happen. Take care to export your data if your storage space is running low.';
    case State.Denied:
      return 'The permission to store entries permanently has been denied. The browser might clear them up, if storage space is running low. It is unlikely, but could happen. Take care to export your data if your storage space is running low.';
    case State.FailedToPersist:
      return 'We could not ensure that entries get stored permanently due to an internal error. Will try again.';
    case State.Prompt:
      return 'This browser might clear entries, if storage space is running low. Please press the button below to give permission to store the entries permanently.';
    case State.Persisted:
      return 'Entries will get stored permanently.';
    default:
      return assertUnreachable(state);
  }
}

function assertUnreachable(x: never): never {
  throw new Error("Didn't expect to get here");
}

export const define = () => {
  window.customElements.define(
    'persistent-storage-indicator',
    PersistentStorageIndicator
  );
};
