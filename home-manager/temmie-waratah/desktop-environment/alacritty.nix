{ lib, pkgs, ... }:
{
  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "alacritty";

      colors = let
        solarized = {
          base03 = "#002b36";
          base02 = "#073642";
          base01 = "#586e75";
          base00 = "#657b83";
          base0  = "#839496";
          base1  = "#93a1a1";
          base2  = "#eee8d5";
          base3  = "#fdf6e3";
        };
        # ayu = {
        #   # colors taken from ayu: https://github.com/ayu-theme/ayu-colors
        #   light.red     = "#f07171"; mirage.red     = "#f28779"; dark.red     = "#f07178"; # syntax.markup
        #   light.green   = "#86b300"; mirage.green   = "#d5ff80"; dark.green   = "#aad94c"; # syntax.string
        #   light.yellow  = "#f2ae49"; mirage.yellow  = "#ffd173"; dark.yellow  = "#ffb454"; # syntax.func
        #   light.blue    = "#55b4d4"; mirage.blue    = "#5ccfe6"; dark.blue    = "#39bae6"; # syntax.tag
        #   light.magenta = "#a37acc"; mirage.magenta = "#dfbfff"; dark.magenta = "#d2a6ff"; # syntax.constant
        #   light.cyan    = "#4cbf99"; mirage.cyan    = "#96e6cb"; dark.cyan    = "#95e6cb"; # syntax.regexp
        #
        #   #light.cyan    = "#55b4d4"; mirage.cyan    = "#5ccfe6"; dark.cyan    = "#39bae6"; # syntax.tag
        #   #light.blue    = "#399ee6"; mirage.blue    = "#73d0ff"; dark.blue    = "#59c2ff"; # syntax.tag
        # };
      in {
        primary.background = "#000816";
        normal.black = solarized.base02;
        bright.black = solarized.base01;
        normal.white = solarized.base2;
        bright.white = solarized.base3;
        primary.foreground = solarized.base3;

        # normal.black = "#252525";
        # bright.black = "#666666";
        # normal.white = "#dbdcdc";
        # bright.white = "#eaeaea";

        # solarized w/ custom bright colours
        normal = {
          red     = "#dc322f";
          green   = "#859900";
          yellow  = "#b58900";
          blue    = "#268bd2";
          magenta = "#d33682";
          cyan    = "#2aa198";
        };

        bright = {
          red     = "#e35d5b";
          green   = "#b1cc00";
          yellow  = "#e8b000";
          blue    = "#4ca2df";
          magenta = "#dc609c";
          cyan    = "#35c9be";
        };

        # normal = { inherit (ayu.dark) red green yellow blue magenta cyan; };
        # bright = { inherit (ayu.mirage) red green yellow blue magenta cyan; };

        draw_bold_text_with_bright_colors = true;
      };

      window.padding = {
        x = 2;
        y = 2;
      };
      window.decorations = "none";
      window.opacity = 0.85;

      font = {
        normal.family = "Cascadia Code PL";

        size = 12.0;
        offset = {
          x = 0;
          y = 1;
        };
      };

      selection.save_to_clipboard = false; # Explicitly require copy command

      cursor.style.shape = "Block";

      # List with all available hints
      #
      # Each hint must have a `regex` and either an `action` or a `command` field.
      # The fields `mouse`, `binding` and `post_processing` are optional.
      #
      # The fields `command`, `binding.key`, `binding.mods`, `binding.mode` and
      # `mouse.mods` accept the same values as they do in the `key_bindings` section.
      #
      # The `mouse.enabled` field controls if the hint should be underlined while
      # the mouse with all `mouse.mods` keys held or the vi mode cursor is above it.
      #
      # If the `post_processing` field is set to `true`, heuristics will be used to
      # shorten the match if there are characters likely not to be part of the hint
      # (e.g. a trailing `.`). This is most useful for URIs.
      #
      # Values for `action`:
      #   - Copy
      #       Copy the hint's text to the clipboard.
      #   - Paste
      #       Paste the hint's text to the terminal or search.
      #   - Select
      #       Select the hint's text.
      #   - MoveViModeCursor
      #       Move the vi mode cursor to the beginning of the hint.
      hints.enabled = [
        {
          regex = ''
            (ipfs:|ipns:|magnet:|mailto:|gemini:|gopher:|https:|http:|news:|file:|git:|ssh:|ftp:)[^<>"\\s{-}\\^⟨⟩`]+'';
          command = "${pkgs.xdg-utils}/bin/xdg-open";
          post_processing = true;
          mouse.enabled = true;
          #mouse.mods = "Control";
          mouse.mods = "None";
        }
        {
          regex = ''[A-Za-z0-9_.-]*(/[A-Za-z0-9_.-]+){3,}'';
          command = "${pkgs.wl-clipboard}/bin/wl-copy";
          post_processing = true;
          mouse.enabled = true;
          #mouse.mods = "Shift";
          mouse.mods = "None";
        }
        {
          regex = ''(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])\\.(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])\\.(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])\\.(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])'';
          command = "${pkgs.wl-clipboard}/bin/wl-copy";
          mouse.enabled = true;
          mouse.mods = "None";
        }
      ];

      # NOTE: We don't use or support vim mode
      keyboard.bindings = [
        # clipboard things
        { key = "Copy"; action = "Copy"; }
        { mods = "Control|Alt"; key = "C"; action = "Copy"; }
        { mods = "Control|Alt"; key = "V"; action = "Paste"; }
        { key = "Paste"; action = "Paste"; }
        { mods = "Shift"; key = "Insert"; action = "PasteSelection"; }

        # navigation
        # QUESTION 2021-10-17 why do we have ~Alt?
        { mods = "Shift"; key = "PageUp"; mode = "~Alt"; action = "ScrollPageUp"; }
        { mods = "Shift"; key = "PageDown"; mode = "~Alt"; action = "ScrollPageDown"; }
        { mods = "Shift"; key = "Home"; mode = "~Alt"; action = "ScrollToTop"; }
        { mods = "Shift"; key = "End"; mode = "~Alt"; action = "ScrollToBottom"; }

        # font sizing
        { mods = "Control"; key = "Equals"; action = "IncreaseFontSize"; }
        { mods = "Control"; key = "Minus"; action = "DecreaseFontSize"; }
        { mods = "Control"; key = "Key0"; action = "ResetFontSize"; }

        # TODO search mode
      ];
    };
  };

  # default terminal for opening Terminal=true desktop apps
  home.packages = [
    (pkgs.writeScriptBin "xdg-terminal-exec" ''
      #!/bin/sh
      exec alacritty -e "$@"
    '')
  ];
}
