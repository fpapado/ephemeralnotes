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
