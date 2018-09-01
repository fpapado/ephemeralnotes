/* This solution uses ShadowDOM for hiding things from the VDOM
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
    this.attachShadow({mode: 'open'});

    // Create the web component's template
    // TODO: consider "title" "description" and "buttonText" attrs
    // We can't really use slots, because of the same VDOM isue
    // I kind of wish we had a shared way of doing styles.
    // Ungrateful, I know...
    this.shadowRoot.innerHTML = `
      <style>
        .vs3 > * + * {
          margin-top: 1rem;
        }
        .flex {
          display: flex;
        }
        .justify-center {
          justify-content: center;
        }
        .items-center {
          align-items: center;
        }
        .measure {
          max-width: 30em;
        }
        .f4 {
          font-size: 1.25rem;
        }
        .f5 {
          font-size: 1rem;
        }
        .lh-title {
          line-height: 1.25;
        }
        .lh-copy {
          line-height: 1.5;
        }
        .bg-white {
          background-color: #fff;
        }
        .near-black {
          color: #111;
        }
        .shadow-1 {
          box-shadow: 0 0 4px 2px rgba(0, 0, 0, 0.2);
        }
        .pa3 {
          padding: 1rem;
        }
        /* TODO: button reset CSS */
        @-webkit-keyframes fadeInUp {
          from {
            opacity: 0;
            -webkit-transform: translate3d(0, 100%, 0);
            transform: translate3d(0, 100%, 0);
          }

          to {
            opacity: 1;
            -webkit-transform: translate3d(0, 0, 0);
            transform: translate3d(0, 0, 0);
          }
        }
        @keyframes fadeInUp {
          from {
            opacity: 0;
            -webkit-transform: translate3d(0, 100%, 0);
            transform: translate3d(0, 100%, 0);
          }

          to {
            opacity: 1;
            -webkit-transform: translate3d(0, 0, 0);
            transform: translate3d(0, 0, 0);
          }
        }
        .fadeInUp {
          -webkit-animation-name: fadeInUp;
          animation-name: fadeInUp;
        }
        .animated {
          -webkit-animation-duration: 1s;
          animation-duration: 1s;
          -webkit-animation-fill-mode: both;
          animation-fill-mode: both;
        }
        @media (prefers-reduced-motion) {
          .animated {
            -webkit-animation: unset !important;
            animation: unset !important;
            -webkit-transition: none !important;
            transition: none !important;
          }
        }
      </style>

      <div class="pa3 flex justify-center items-center bg-white near-black shadow-1 animated fadeInUp">
        <div class="measure vs3">
          <h2 class="f4 fw7 lh-title">Install App</h2>
          <p class="f5 lh-copy">
            You can install Ephemeral to your homescreen for
            quicker access and standalone use. It will still
            be available offline through the browser if you
            do not.
          </p>
        </div>
        <button id="install-button">
          Install
        </button>
        <button id="dismiss-button">
          Dismiss
        </button>
      </div>`;
  }

  connectedCallback() {
    // Hide the banner by default
    this.shadowRoot.host.style.display = 'none';

    // Get a reference to the buttons
    const installButton = this.shadowRoot.getElementById('install-button');
    const dismissButton = this.shadowRoot.getElementById('dismiss-button');

    // Show interface for installation
    // TODO: clean up in disconnectedCallback()
    window.addEventListener('beforeinstallprompt', e => {
      console.log('Before install');
      // Prevent Chrome 67 and earlier from automatically showing the prompt
      e.preventDefault();
      // Stash the event so it can be triggered later.
      this._deferredPrompt = e;

      // Dispatch a custom event, in case the caller wants to do something
      this.dispatchEvent(new CustomEvent('beforeInstallPrompt'));

      // Show the banner
      this.shadowRoot.host.style.display = 'block';
    });

    installButton.addEventListener('click', e => {
      // Hide the banner, since we can only prompt once
      this.shadowRoot.host.style.display = 'none';

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

    dismissButton.addEventListener('click', _e => {
      // Hide the banner, the user doesn't like it
      this.shadowRoot.host.style.display = 'none';
    });
  }

  // Clean up event listeners
  disconnectedCallback() {
    /*
    const installButton = this.shadowRoot.getElementById('install-button');
    this.removeEventListener('beforeinstallprompt', this._boundOnBeforeInstallPrompt);
    installButton.removeEventListener('click', this._boundOnInstallButtonClick);
    */
  }
}
