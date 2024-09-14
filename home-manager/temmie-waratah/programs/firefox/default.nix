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

        :root {
          font-size: 16px !important; /* scale with ui.textScaleFactor */
        }

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
          display: none !important;
        }
      '';

      settings = {
        # download to /tmp instead of ~/Downloads
        "browser.download.start_downloads_in_tmp_dir" = true;

        # helpful features in urlbar
        "browser.urlbar.suggest.calculator" = true;
        "browser.urlbar.unitConversion.enabled" = true;

        # Disable Features ====================================================

        # disable disk cache
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.enable" = true;

        # disable c-q closing browser
        "browser.quitShortcut.disable" = true;

        # disable vpn promo controversy
        "browser.vpn_promo.enabled" = false;

        # disable builtin pocket extension
        "extensions.pocket.enabled" = false;

        # disable the webrtc sharing icon that was also causing crashes
        "privacy.webrtc.legacyGlobalIndicator" = false;

        # UI scale ============================================================

        # enable support for fractional scaling on wayland
        "widget.wayland.fractional-scale.enabled" = true;

        # See <https://searchfox.org/mozilla-beta/rev/82a1e3f4e6d7c018b065f366ac7bb30e35a052ff/modules/libpref/init/StaticPrefList.yaml#8616-8623>
        "layout.css.devPixelsPerPx" = -1; # Use display DPI information, instead of static value
        "ui.textScaleFactor" = 133; # Scale factor
        "browser.display.os-zoom-behavour" = 1; # Have "OS Zoom Settings affect full zoom (dpi, effectively)". I have no idea where OS Zoom comes from... maybe /org/gnome/desktop/interface/text-scaling-factor? <https://bugzilla.mozilla.org/show_bug.cgi?id=1833164>
      };
    };
  };
}
