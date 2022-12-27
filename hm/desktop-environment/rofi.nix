{ config, pkgs, ... }:
with config;
let
  inherit (pkgs) lib;

  rofi-theme = ''
    /* vim:set ft=css: */

    * {
        s-bg: #000000;
        s-bg50: #00000080;
        s-bg75: #000000c0;
        s-bgx: #45454530;
        s-bgy: #45454550;
        s-fg: #ffffff;
        s-fg50: #ffffff80;
        s-fg75: #ffffffc0;

        s-0:  #252525;
        s-1:  #ef6769;
        s-2:  #a6e22e;
        s-3:  #fd971f;
        s-4:  #6495ed;
        s-5:  #deb887;
        s-6:  #b0c4de;
        s-7:  #dbdcdc;
        s-8:  #454545;
        s-9:  #ef6769;
        s-10: #a6e22e;
        s-11: #fd971f;
        s-12: #6495ed;
        s-13: #deb887;
        s-14: #b0c4de;
        s-15: #dbdcdc;
    }

    * {
        s-bgx: #2e2f3480;
        s-bgy: #2e2f34c0;

        background-color: #0000;
        text-color: @s-fg75;
        font: "sans-serif 12";
    }

    window {
        background-color: @s-bg75;
        width: 800px;
        height: 500px;
    }

    mainbox {
        padding: 5px;
        border-radius: 3px;
    }

    textbox-prompt {
        expand: false;
        text-style: bold;
        str: "――";
        margin: 0px 0.3em;
    }

    prompt {
        text-color: @s-fg50;
    }

    entry {
        text-color: @s-fg;
    }

    inputbar {
        background-color: @s-bgy;
        padding: 8px;
        children: [ textbox-prompt, entry, prompt, case-indicator ];
    }

    listview {
        border: 0px 0;
        padding: 1em 1em 0.5em;
        border-color: @s-4;
    }

    element {
        padding: 8px;
        margin: 2px 0;
        background-color: @s-bgx;
    }

    element.selected {
        background-color: @s-8;
        text-color: white;
    }

    button.selected {
        text-color: white;
    }
  '';
in
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;

    theme = "${pkgs.writeText "theme.rasi" rofi-theme}";

    extraConfig = {
      show-icons = true;
      sidebar-mode = false;

      modi = "combi";
      combi-hide-mode-prefix = true;
      combi-modi =
        let
          get-entries = pkgs.writeScript "get-entries" ''
            #!${pkgs.bash}/bin/bash
            get_entries() {
              cd "$HOME" || exit
              find -L /tmp -maxdepth 1 -print
              find -L . ./Downloads ./work -maxdepth 2 -print
              find -L ./Documents -print
              find -L ./projects -path ./projects/pacman -prune -o -name ".?*" -prune -o -name "build" -prune -o -print
              # find -L . -name ".?*" -prune -o -name "build" -prune -o -path ~/Android -prune -o -print
            }
            get_entries > "$1"
          '';
          rofi-files = pkgs.writeScript "rofi-files" ''
            #!${pkgs.bash}/bin/bash

            if [ -n "$*" ]; then
              # We're given a prompt
              coproc xdg-open "$*" >/dev/null 2>&1
            else
              # Startup - populate entries
              SAVE="$HOME/.cache/rofi-files"
              if [ -f "$SAVE" ]; then
                cat "$SAVE"
              else
                echo ""
              fi
              coproc ${get-entries} "$SAVE"
            fi
          '';
        in
        "drun,files:${rofi-files}";
    };
  };
}
