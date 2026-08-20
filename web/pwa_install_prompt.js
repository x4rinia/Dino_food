/**
 * Dino_food PWA Install Prompt
 * Exclusively provides a discreet web-level install hint for mobile browsers (iOS Safari & Android/Chromium).
 * Completely isolated from Flutter app logic.
 */
(function () {
  const DISMISSED_KEY = 'dino_food_pwa_prompt_dismissed';

  function isStandalone() {
    return (
      window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true ||
      document.referrer.includes('android-app://')
    );
  }

  function isDismissed() {
    try {
      return localStorage.getItem(DISMISSED_KEY) === 'true';
    } catch (e) {
      return false;
    }
  }

  function setDismissed() {
    try {
      localStorage.setItem(DISMISSED_KEY, 'true');
    } catch (e) {}
  }

  function isIOS() {
    const ua = window.navigator.userAgent.toLowerCase();
    return (
      /iphone|ipad|ipod/.test(ua) ||
      (window.navigator.platform === 'MacIntel' && window.navigator.maxTouchPoints > 1)
    );
  }

  let deferredPrompt = null;
  let bannerElement = null;

  function createBanner({ title, text, buttons }) {
    if (bannerElement || isStandalone() || isDismissed()) return;

    const styleId = 'dino-pwa-banner-style';
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style');
      style.id = styleId;
      style.textContent = `
        .dino-pwa-overlay {
          position: fixed;
          bottom: 16px;
          left: 50%;
          transform: translateX(-50%) translateY(120%);
          width: calc(100% - 32px);
          max-width: 440px;
          background: #ffffff;
          border-radius: 18px;
          box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15), 0 1px 3px rgba(0, 0, 0, 0.08);
          border: 1px solid rgba(62, 155, 79, 0.15);
          padding: 16px;
          z-index: 999999;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          box-sizing: border-box;
          transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1);
          color: #1c2b1e;
        }
        .dino-pwa-overlay.dino-pwa-visible {
          transform: translateX(-50%) translateY(0);
        }
        .dino-pwa-header {
          display: flex;
          align-items: center;
          gap: 10px;
          margin-bottom: 8px;
        }
        .dino-pwa-icon {
          width: 36px;
          height: 36px;
          border-radius: 9px;
          box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
          flex-shrink: 0;
        }
        .dino-pwa-title {
          font-size: 15px;
          font-weight: 700;
          color: #244b2d;
          margin: 0;
          line-height: 1.25;
        }
        .dino-pwa-text {
          font-size: 13.5px;
          color: #4a5c4e;
          margin: 0 0 14px 0;
          line-height: 1.45;
        }
        .dino-pwa-actions {
          display: flex;
          justify-content: flex-end;
          gap: 8px;
        }
        .dino-pwa-btn {
          border: none;
          outline: none;
          padding: 8px 16px;
          border-radius: 10px;
          font-size: 13.5px;
          font-weight: 600;
          cursor: pointer;
          transition: background-color 0.15s ease, opacity 0.15s ease;
          -webkit-tap-highlight-color: transparent;
        }
        .dino-pwa-btn-primary {
          background-color: #3E9B4F;
          color: #ffffff;
        }
        .dino-pwa-btn-primary:active {
          background-color: #317f40;
        }
        .dino-pwa-btn-secondary {
          background-color: #edf5ef;
          color: #385e40;
        }
        .dino-pwa-btn-secondary:active {
          background-color: #deece1;
        }
      `;
      document.head.appendChild(style);
    }

    const banner = document.createElement('div');
    banner.className = 'dino-pwa-overlay';

    let buttonsHtml = '';
    buttons.forEach((btn, idx) => {
      const btnClass = btn.primary ? 'dino-pwa-btn-primary' : 'dino-pwa-btn-secondary';
      buttonsHtml += `<button class="dino-pwa-btn ${btnClass}" id="dino-pwa-btn-${idx}">${btn.label}</button>`;
    });

    banner.innerHTML = `
      <div class="dino-pwa-header">
        <img class="dino-pwa-icon" src="icons/apple-touch-icon.png" alt="Dino_food">
        <h3 class="dino-pwa-title">${title}</h3>
      </div>
      <p class="dino-pwa-text">${text}</p>
      <div class="dino-pwa-actions">${buttonsHtml}</div>
    `;

    document.body.appendChild(banner);
    bannerElement = banner;

    // Trigger animation
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        banner.classList.add('dino-pwa-visible');
      });
    });

    buttons.forEach((btn, idx) => {
      const el = document.getElementById(`dino-pwa-btn-${idx}`);
      if (el) {
        el.addEventListener('click', () => {
          btn.onClick();
        });
      }
    });
  }

  function dismissBanner() {
    if (!bannerElement) return;
    bannerElement.classList.remove('dino-pwa-visible');
    setDismissed();
    setTimeout(() => {
      if (bannerElement && bannerElement.parentNode) {
        bannerElement.parentNode.removeChild(bannerElement);
      }
      bannerElement = null;
    }, 400);
  }

  // Android / Chromium beforeinstallprompt handling
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;

    if (!isStandalone() && !isDismissed()) {
      createBanner({
        title: '🦕 Dino_food als App installieren',
        text: 'Öffne Dino_food direkt von deinem Startbildschirm.',
        buttons: [
          {
            label: 'Später',
            primary: false,
            onClick: () => {
              dismissBanner();
            },
          },
          {
            label: 'Installieren',
            primary: true,
            onClick: () => {
              if (deferredPrompt) {
                deferredPrompt.prompt();
                deferredPrompt.userChoice.finally(() => {
                  deferredPrompt = null;
                  dismissBanner();
                });
              } else {
                dismissBanner();
              }
            },
          },
        ],
      });
    }
  });

  // iOS Safari guidance
  function checkIOSGuidance() {
    if (isIOS() && !isStandalone() && !isDismissed()) {
      // Delay slightly so the web page finishes loading cleanly
      setTimeout(() => {
        if (!isStandalone() && !isDismissed()) {
          createBanner({
            title: '🦕 Dino_food zum Home-Bildschirm hinzufügen',
            text: 'Tippe auf Teilen und anschließend auf „Zum Home-Bildschirm“. Danach kann Dino_food wie eine Web-App vom Home-Bildschirm geöffnet werden.',
            buttons: [
              {
                label: 'Verstanden',
                primary: true,
                onClick: () => {
                  dismissBanner();
                },
              },
            ],
          });
        }
      }, 2500);
    }
  }

  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    checkIOSGuidance();
  } else {
    window.addEventListener('DOMContentLoaded', checkIOSGuidance);
  }
})();
