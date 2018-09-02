export function listenForWaitingSW(reg, cb) {
  function awaitStateChange() {
    reg.installing.addEventListener('statechange', function() {
      if (this.state === 'installed') cb(reg);
    });
  }
  if (!reg) return;
  if (reg.waiting) return cb(reg);
  if (reg.installing) awaitStateChange();
  reg.addEventListener('updatefound', awaitStateChange);
}
