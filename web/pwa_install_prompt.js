/**
 * Dino_food PWA Install Prompt
 * Exclusively provides a discreet web-level install hint for mobile browsers (iOS Safari & Android/Chromium).
 * Completely isolated from Flutter app logic.
 */
(function () {
  const IOS_DISMISSED_KEY = 'dino_food_ios_install_hint_v3';
  const ANDROID_DISMISSED_KEY = 'dino_food_pwa_hint_v2';

  function isStandalone() {
    try {
      const isDisplayStandalone = window.matchMedia && window.matchMedia('(display-mode: standalone)').matches;
      const isNavStandalone = window.navigator && window.navigator.standalone === true;
      return Boolean(isDisplayStandalone || isNavStandalone);
    } catch (e) {
      return false;
    }
  }

  function isIOSDismissed() {
    try {
      return localStorage.getItem(IOS_DISMISSED_KEY) === 'true';
    } catch (e) {
      return false;
    }
  }

  function setIOSDismissed() {
    try {
      localStorage.setItem(IOS_DISMISSED_KEY, 'true');
    } catch (e) {}
  }

  function isAndroidDismissed() {
    try {
      return localStorage.getItem(ANDROID_DISMISSED_KEY) === 'true';
    } catch (e) {
      return false;
    }
  }

  function setAndroidDismissed() {
    try {
      localStorage.setItem(ANDROID_DISMISSED_KEY, 'true');
    } catch (e) {}
  }

  function isIOS() {
    const ua = window.navigator.userAgent || window.navigator.vendor || window.opera || '';
    const platform = window.navigator.platform || '';
    const maxTouchPoints = window.navigator.maxTouchPoints || 0;

    // Direct iPhone, iPod, iPad UA check
    const isDirectAppleMobile = /iPhone|iPod/i.test(ua) || /iPad/i.test(ua);

    // iPadOS 13+ reports as Macintosh in UA & platform, but has multi-touch
    const isIPadDesktopMode =
      (/Macintosh|MacIntel/i.test(platform) || /Macintosh/i.test(ua)) && maxTouchPoints > 1;

    // General Apple device with touch (excluding Windows/Android/Linux)
    const isAppleWithTouch =
      (/Apple/i.test(window.navigator.vendor || '') || /Safari/i.test(ua)) &&
      maxTouchPoints > 0 &&
      !/Windows|Android|Linux/i.test(ua);

    return Boolean(isDirectAppleMobile || isIPadDesktopMode || isAppleWithTouch);
  }

  let deferredPrompt = null;
  let bannerElement = null;

  function createBanner({ title, text, buttons, onDismiss }) {
    if (bannerElement || isStandalone()) return;

    const styleId = 'dino-pwa-banner-style';
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style');
      style.id = styleId;
      style.textContent = `
        .dino-pwa-overlay {
          position: fixed !important;
          bottom: calc(20px + env(safe-area-inset-bottom, 0px)) !important;
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
        <img class="dino-pwa-icon" src="icons/apple-touch-icon.png" alt="Dino_food" onerror="this.style.display='none'">
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

  function dismissBanner(callback) {
    if (!bannerElement) return;
    bannerElement.classList.remove('dino-pwa-visible');
    if (typeof callback === 'function') {
      callback();
    }
    setTimeout(() => {
      if (bannerElement && bannerElement.parentNode) {
        bannerElement.parentNode.removeChild(bannerElement);
      }
      bannerElement = null;
    }, 400);
  }

  // Android / Windows / Chromium beforeinstallprompt handling (preserved untouched)
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;

    if (!isStandalone() && !isAndroidDismissed()) {
      createBanner({
        title: '🦕 Dino_food als App installieren',
        text: 'Öffne Dino_food direkt von deinem Startbildschirm.',
        onDismiss: setAndroidDismissed,
        buttons: [
          {
            label: 'Später',
            primary: false,
            onClick: () => {
              dismissBanner(setAndroidDismissed);
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
                  dismissBanner(setAndroidDismissed);
                });
              } else {
                dismissBanner(setAndroidDismissed);
              }
            },
          },
        ],
      });
    }
  });

  // iPhone / iPadOS browser guidance
  function checkIOSGuidance() {
    if (!isIOS()) return;
    if (isStandalone()) return;
    if (isIOSDismissed()) return;

    if (!document.body) {
      setTimeout(checkIOSGuidance, 500);
      return;
    }

    createBanner({
      title: '🦕 Dino_food als App hinzufügen',
      text: 'Öffne das Teilen-Menü deines Browsers und wähle „Zum Home-Bildschirm“ bzw. „Zu Home-Bildschirm hinzufügen“. Aktiviere, falls angeboten, „Als Web-App öffnen“ und tippe anschließend auf „Hinzufügen“.',
      onDismiss: setIOSDismissed,
      buttons: [
        {
          label: 'Verstanden',
          primary: true,
          onClick: () => {
            dismissBanner(setIOSDismissed);
          },
        },
      ],
    });
  }

  function init() {
    if (document.readyState === 'complete') {
      setTimeout(checkIOSGuidance, 800);
    } else {
      window.addEventListener('load', () => {
        setTimeout(checkIOSGuidance, 800);
      });
      document.addEventListener('DOMContentLoaded', () => {
        setTimeout(checkIOSGuidance, 800);
      });
    }
  }

  init();
})();
