/**
 * Dino_food PWA Install Prompt
 * Exclusively provides a discreet web-level install hint for mobile browsers (iOS Safari & Android/Chromium).
 * Completely isolated from Flutter app logic.
 */
(function () {
  const DISMISSED_KEY = 'dino_food_pwa_hint_v2';

  function isStandalone() {
    const isStandaloneDisplay = window.matchMedia && window.matchMedia('(display-mode: standalone)').matches;
    const isNavStandalone = window.navigator.standalone === true;
    return isStandaloneDisplay || isNavStandalone;
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
    const ua = window.navigator.userAgent || window.navigator.vendor || window.opera || '';
    const isAppleDevice = /iPad|iPhone|iPod/.test(ua) && !window.MSStream;
    const isAppleTouch =
      (window.navigator.platform === 'MacIntel' || /Macintosh/.test(ua)) &&
      window.navigator.maxTouchPoints > 1;
    return isAppleDevice || isAppleTouch;
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
          position: fixed !important;
          bottom: 20px !important;
          left: 50% !important;
          transform: translateX(-50%) translateY(140%) !important;
          width: calc(100% - 32px) !important;
          max-width: 440px !important;
          background: #ffffff !important;
          border-radius: 18px !important;
          box-shadow: 0 12px 36px rgba(0, 0, 0, 0.2), 0 2px 6px rgba(0, 0, 0, 0.08) !important;
          border: 1px solid rgba(62, 155, 79, 0.25) !important;
          padding: 16px 18px !important;
          z-index: 2147483647 !important;
          pointer-events: auto !important;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif !important;
          box-sizing: border-box !important;
          transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1) !important;
          color: #1c2b1e !important;
        }
        .dino-pwa-overlay.dino-pwa-visible {
          transform: translateX(-50%) translateY(0) !important;
        }
        .dino-pwa-header {
          display: flex !important;
          align-items: center !important;
          gap: 10px !important;
          margin-bottom: 8px !important;
        }
        .dino-pwa-icon {
          width: 38px !important;
          height: 38px !important;
          border-radius: 10px !important;
          box-shadow: 0 2px 6px rgba(0, 0, 0, 0.12) !important;
          flex-shrink: 0 !important;
        }
        .dino-pwa-title {
          font-size: 15.5px !important;
          font-weight: 700 !important;
          color: #244b2d !important;
          margin: 0 !important;
          line-height: 1.25 !important;
        }
        .dino-pwa-text {
          font-size: 13.5px !important;
          color: #435447 !important;
          margin: 0 0 14px 0 !important;
          line-height: 1.45 !important;
        }
        .dino-pwa-actions {
          display: flex !important;
          justify-content: flex-end !important;
          gap: 10px !important;
        }
        .dino-pwa-btn {
          border: none !important;
          outline: none !important;
          padding: 9px 18px !important;
          border-radius: 10px !important;
          font-size: 14px !important;
          font-weight: 600 !important;
          cursor: pointer !important;
          transition: background-color 0.15s ease, opacity 0.15s ease !important;
          -webkit-tap-highlight-color: transparent !important;
        }
        .dino-pwa-btn-primary {
          background-color: #3E9B4F !important;
          color: #ffffff !important;
        }
        .dino-pwa-btn-primary:active {
          background-color: #317f40 !important;
        }
        .dino-pwa-btn-secondary {
          background-color: #edf5ef !important;
          color: #385e40 !important;
        }
        .dino-pwa-btn-secondary:active {
          background-color: #deece1 !important;
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

    // Trigger slide-in animation
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        banner.classList.add('dino-pwa-visible');
      });
    });

    buttons.forEach((btn, idx) => {
      const el = document.getElementById(`dino-pwa-btn-${idx}`);
      if (el) {
        el.addEventListener('click', (e) => {
          e.stopPropagation();
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
      setTimeout(() => {
        if (!isStandalone() && !isDismissed()) {
          createBanner({
            title: '🦕 Dino_food zum Home-Bildschirm hinzufügen',
            text: 'Tippe auf Teilen und anschließend auf „Zum Home-Bildschirm“. Danach kannst du Dino_food wie eine App öffnen.',
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
      }, 1200);
    }
  }

  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    checkIOSGuidance();
  } else {
    window.addEventListener('DOMContentLoaded', checkIOSGuidance);
  }
})();
