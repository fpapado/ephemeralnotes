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

    // Create a Shadow Root and fill it with the template
    // Playing hide-and-seek with the VDOM
    this.attachShadow({ mode: "open" });

    // Create the web component's template
    // TODO: consider "title" "description" and "buttonText" attrs
    // We can't really use slots, because of the same VDOM isue
    this.shadowRoot.innerHTML = `
      <div class="flex">
        <div>
          <h2 class="f4 fw7 lh-title">Install App</h2>
          <p class="f6 f5-ns lh-copy">
            You can install Ephemeral to your homescreen for
            quicker access and standalone use.
          </p>
        </div>
        <button id="install-button">
          Install
        </button>
      </div>
    `;
  }

  connectedCallback() {
    // Hide the banner by default
    // this.shadowRoot.host.style.display = "none";

    // Get a reference to the button
    const installButton = this.shadowRoot.getElementById("install-button");

    // Show interface for installation
    // TODO: clean up in disconnectedCallback()
    window.addEventListener("beforeinstallprompt", e => {
      // Prevent Chrome 67 and earlier from automatically showing the prompt
      e.preventDefault();
      // Stash the event so it can be triggered later.
      this._deferredPrompt = e;

      // Dispatch a custom event, in case the caller wants to do something
      this.dispatchEvent(new CustomEvent("beforeInstallPrompt"));

      // Show the banner
      this.shadowRoot.host.style.display = "none";
    });

    installButton.addEventListener("click", e => {
      // Hide the banner, since we can only prompt once
      this.shadowRoot.host.style.display = "none";

      // Show the prompt
      this._deferredPrompt.prompt();

      // Wait for the user to respond to the prompt
      this._deferredPrompt.userChoice.then(choiceResult => {
        if (choiceResult.outcome === "accepted") {
          this.dispatchEvent(new CustomEvent("installAccepted"));
          console.log("User accepted the A2HS prompt");
        } else {
          this.dispatchEvent(new CustomEvent("installDismissed"));
          console.log("User dismissed the A2HS prompt");
        }
        this._deferredPrompt = null;
      });
    });
  }

  // Clean up event listener
  disconnectedCallback() {
    /*
    const installButton = this.shadowRoot.getElementById('install-button');
    this.removeEventListener('beforeinstallprompt', this._boundOnBeforeInstallPrompt);
    installButton.removeEventListener('click', this._boundOnInstallButtonClick);
    */
  }
}
