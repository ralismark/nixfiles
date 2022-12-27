{ config, pkgs, ... }:
with config;
let
  inherit (pkgs) lib;
in
{
  programs.alacritty = {
    # see https://github.com/alacritty/alacritty/blob/master/alacritty.yml
    # last updated: 2021-10-17, for v0.9.0
    # (hotfixed window.opacity 2022-02-06)
    enable = true;

    settings = {
      env.TERM = "xterm-256color";

      colors = {
        primary.background = "#010016";
        primary.foreground = "#ffffff";

        normal.black = "#252525";
        normal.red = "#ef6769";
        normal.green = "#a6e22e";
        normal.yellow = "#fd971f";
        normal.blue = "#6495ed";
        normal.magenta = "#deb887";
        normal.cyan = "#b0c4de";
        normal.white = "#dbdcdc";
      };

      window.padding = {
        x = 2;
        y = 2;
      };
      window.decorations = "none";
      window.opacity = 0.75;

      font = {
        normal.family = "Cascadia Code PL";

        size = 13.0;
        offset = {
          x = 0;
          y = 1;
        };
      };
      draw_bold_text_with_bright_colors = true;

      selection.save_to_clipboard = false; # Explicitly require copy command

      cursor.shape = "Block";

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
          command = "${pkgs.xdg_utils}/bin/xdg-open";
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
      key_bindings = [
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
}
