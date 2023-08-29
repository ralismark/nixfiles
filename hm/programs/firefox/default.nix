{ lib
, pkgs
, ... }:
with lib;
{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;

    profiles.dev-edition-default = {
      id = 1;
      path = "default"; # link to default one
    };

    profiles.default = {
      id = 0;
      name = "dev-edition-default";

      userChrome = ''
        /*** general cleanup *************************************************/

        /* remove unnecessary things from tab bar */
        #tabs-newtab-button, #new-tab-button, /* new tab buttons */
        #alltabs-button, /* down arrow at end of tab list */
        end-of-list {
          display: none !important;
        }

        /* make tabs always expand to fill the space */
        .tabbrowser-tab[fadein]:not([pinned]) {
          /* tabs that are doing a closing animation don't have [fadein] */
          max-width: 100% !important;
        }

        /* only show tab close buttons when hovering */
        .tabbrowser-tab:not([pinned]):not(:hover) .tab-close-button {
          display: none;
        }
        .tabbrowser-tab:not([pinned]):hover .tab-close-button {
          display: inline-flex !important;
        }

        /*** centre things ***************************************************/

        /* urlbar */
        #urlbar-input {
          text-align: center !important;
        }

        /* bookmark bar */
        #PlacesToolbarItems {
          justify-content: center;
        }

        /*** hide tabbar when only one tab open ******************************/

        .tabbrowser-tab:only-of-type {
          visibility: collapse;
        }

        #tabbrowser-tabs {
          --tab-min-height: 0;
        }

        /*** number tabs *****************************************************/

        #tabbrowser-tabs {
          counter-reset: tab;
        }

        .tabbrowser-tab {
          counter-increment: tab;
        }

        .tabbrowser-tab .tab-label::before {
          content: counter(tab);
          padding: 1px 4px;
          border-radius: 4px;
          background: #123;
          color: #8cf;
          margin-right: 4px;
        }

        /*** disable DRM disabled warning banner *****************************/

        notification-message[value="drmContentDisabled"] {
          display: none;
        }
      '';

      settings = {
        # disable the webrtc sharing icon that was also causing crashes
        "privacy.webrtc.legacyGlobalIndicator" = false;

        # disable builtin pocket extension
        "extensions.pocket.enabled" = false;

        # download to /tmp instead of ~/Downloads
        "browser.download.start_downloads_in_tmp_dir" = true;

        # recent vpn promo controversy
        "browser.vpn_promo.enabled" = false;

        # helpful features in urlbar
        "browser.urlbar.suggest.calculator" = true;
        "browser.urlbar.unitConversion.enabled" = true;

        # disable disk cache
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.enable" = true;

        # disable c-q closing browser
        "browser.quitShortcut.disable" = true;
      };
    };
  };
}
