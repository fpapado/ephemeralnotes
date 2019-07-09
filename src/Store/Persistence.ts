export {Persistence, tryPersistWithoutPromptingUser, tryPersistWithPrompt};

// This could also be expressed as an an enum. Tbh I don't think it changes much!
type Persistence =
  | 'Persisted'
  | 'ShouldPrompt'
  | 'Unsupported'
  | 'Denied'
  | 'Failed';

const Persisted = 'Persisted';
const Unsupported = 'Unsupported';
const ShouldPrompt = 'ShouldPrompt';
const Denied = 'Denied';
const Failed = 'Failed';

/** Try to persist storage without ever prompting the user.
  @returns {Promise<Persistence>}
    - "Unsupported" In case persisting is not ever possible. Caller don't bother
        asking user for permission.
    - "ShouldPrompt" In case persisting would be possible if prompting user first.
    - "Persisted" In case this call successfully silently persisted the storage,
        or if it was already persisted.
    - "Failed" Persistence is supported, but it failed for some reason
    - "Denied" The user or UA has denied the Persistence Permission
  @see https://dexie.org/docs/StorageManager
*/
async function tryPersistWithoutPromptingUser(): Promise<Persistence> {
  if (!navigator.storage || !navigator.storage.persisted) {
    // Storage or storage.persisted is not supported; could never succeed
    return Unsupported;
  }
  let persisted = await navigator.storage.persisted();
  if (persisted === true) {
    // Already persisted previously
    return Persisted;
  }
  if (!navigator.permissions || !navigator.permissions.query) {
    // The permissions API is not available, so we must prompt directly
    // It MAY be successful to prompt. We don't know.
    return ShouldPrompt;
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
      return Persisted;
    } else {
      return Failed;
    }
  }
  // If the Permission API tells us to prompt, well, we prompt!
  else if (permission.state === 'prompt') {
    return ShouldPrompt;
  }
  // If the Permission API tells us it's denied, then inform that
  else if (permission.state === 'denied') {
    return Denied;
  }
  // If all else fails, it is not possible to persist
  return Unsupported;
}

/** Request persistence with `.prompt`, which may prompt the user. */
async function tryPersistWithPrompt(): Promise<Persistence> {
  if (!navigator.storage || !navigator.storage.persisted) {
    // Storage or storage.persisted is not supported; could never succeed
    return Unsupported;
  }
  let persisted = await navigator.storage.persisted();
  if (persisted === true) {
    // Already persisted previously, nothing to do
    return Persisted;
  }
  persisted = await navigator.storage.persist();
  if (persisted) {
    return Persisted;
  } else {
    return Failed;
  }
}
