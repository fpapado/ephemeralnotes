/* This implementation relies a lot on calling back to
 * the consumer with CustomEvents, and customising the
 * text. It is a bit weird that we have the listeners
 * on the button, and not on the "banner" per se.
 *
 * This is because nesting markup inside a custom element
 * does not work well with VDOM; it will be overwritten.
 *
 * There are thus two options:
 *  - Use Shadow DOM and make the behaviour completely self-contained
 *    including any children/buttons/etc.
 *  - "Collapse" the functionality into the minimal markup, and
 *    rely on the Elm side reactivity to show/hide the banner.
 *    This would mean only showing the button with the onClick,
 *    and relying on the view above to fill in the rest.
*/
export class InstallBanner extends HTMLElement {
  constructor() {
    super();
    this._deferredPrompt;
    this.setAttribute('role', 'region');
  }

  // TODO: customisable text, class
  connectedCallback() {
    this.innerHTML = 'Add to home screen';
    this.style.display = 'none';

    // Show interface for installation
    window.addEventListener('beforeinstallprompt', e => {
      // Prevent Chrome 67 and earlier from automatically showing the prompt
      e.preventDefault();
      // Stash the event so it can be triggered later.
      this._deferredPrompt = e;
      this.dispatchEvent(new CustomEvent('beforeInstallPrompt'));
      this.style.display = 'block';
    });

    this.addEventListener('click', e => {
      // hide our user interface that shows our A2HS button
      this.style.display = 'none';

      // Show the prompt
      this._deferredPrompt.prompt();

      // Wait for the user to respond to the prompt
      this._deferredPrompt.userChoice.then(choiceResult => {
        if (choiceResult.outcome === 'accepted') {
          this.dispatchEvent(new CustomEvent('installAccepted'));
          console.log('User accepted the A2HS prompt');
        } else {
          this.dispatchEvent(new CustomEvent('installDismissed'));
          console.log('User dismissed the A2HS prompt');
        }
        this._deferredPrompt = null;
      });
    });
  }
}
