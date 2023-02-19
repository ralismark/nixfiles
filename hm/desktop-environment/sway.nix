{ config, lib, pkgs, ... }:
let
  cfg = config.wayland.windowManager.sway;
in
{
  home.shellAliases = lib.mkIf cfg.enable {
    left-handed = "${cfg.package}/bin/swaymsg input type:pointer left_handed enabled";
    right-handed = "${cfg.package}/bin/swaymsg input type:pointer left_handed disabled";
  };

  wayland.windowManager.sway = {
    enable = true;
    systemdIntegration = false; # We do our own custom systemd integration

    config =
      let
        # we use systemd to move the processes out of sway.service
        # TODO why double systemd-run?
        exec = "${pkgs.systemd}/bin/systemd-run --user -- ${pkgs.systemd}/bin/systemd-run --user --scope --slice=app-graphical.slice";

        per-workspace = fn:
          # key name
          fn "1" "1" //
          fn "2" "2" //
          fn "3" "3" //
          fn "4" "4" //
          fn "5" "5" //
          fn "6" "6" //
          fn "7" "7" //
          fn "8" "8" //
          fn "9" "9" //
          fn "0" "10";

        per-direction = fn:
          # key dir
          fn "h" "left" //
          fn "j" "down" //
          fn "k" "up" //
          fn "l" "right";
      in
      rec {
        modifier = "Mod4"; # Window key

        menu = "${exec} ${config.programs.rofi.package}/bin/rofi -show combi";
        terminal = "${exec} ${config.programs.alacritty.package}/bin/alacritty";

        bars = [ ]; # managed separately

        colors.focused = {
          border = "#22aacc";
          background = "#22aacc";
          text = "#ffffff";
          indicator = "";
          childBorder = "";
        };

        gaps.inner = 5;
        gaps.outer = 0;

        keybindings = {
          "--locked ${modifier}+q" = ''exec "swaylock -f; ${pkgs.systemd}/bin/systemctl suspend"'';

          # Start a terminal
          "${modifier}+Return" = "exec ${terminal}";

          # Unicode picker # TODO make this work
          # "${modifier}+u" = "exec ${exec} rofi-unicode"; # TODO don't do path search for rofi-unicode

          # Kill focused window
          "${modifier}+w" = "kill";

          # Start your launcher # TODO make this work
          "${modifier}+Space" = "exec ${menu}";

          # dropdown terminal
          "${modifier}+Tab" =
            let
              tmux = "${config.programs.tmux.package}/bin/tmux";
              # TODO avoid path search
              # TODO extract out name
              dropper = pkgs.writeScript "dropper" ''
                #!/bin/sh

                session_name=drop
                name=tdrop

                if [ -z "$(${tmux} list-clients -t "$session_name")" ]; then
                  exec ${cfg.config.terminal} --class "$name" --command ${tmux} new-session -Ads "$session_name"
                else
                  exec ${tmux} detach-client -s "$session_name"
                fi
              '';
            in
            "exec ${exec} ${dropper}";

          # Special Keys ------------------------------------------------------

          # media buttons
          # TODO make these work
          XF86AudioMute = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
          XF86AudioRaiseVolume = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +10%";
          XF86AudioLowerVolume = "exec ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -10%";

          # do these even work
          XF86AudioPlay = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          XF86AudioNext = "exec ${pkgs.playerctl}/bin/playerctl next";
          XF86AudioPrev = "exec ${pkgs.playerctl}/bin/playerctl previous";

          XF86MonBrightnessDown = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
          XF86MonBrightnessUp = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%+";

          # TODO make this work
          Print =
            let
              snip-script = ''
                #!${pkgs.bash}/bin/bash

                temp="$(mktemp -p /tmp XXXXXXXXXX.png)"
                ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp || exit)" "$temp" && {
                  ${pkgs.wl-clipboard}/bin/wl-copy -t image/png < "$temp"
                  ${pkgs.xdragon}/bin/dragon "$temp"
                }

                # allow programs to take this file, then cleanup
                sleep 300
                rm "$temp"
              '';
            in
            "exec ${exec} ${pkgs.writeScript "snip" snip-script}";

          # Layout Management --------------------------------------------------

          # maybe binds that make more sense?
          "${modifier}+a" = "floating disable";
          "${modifier}+s" = "layout toggle all";
          "${modifier}+d" = "floating enable";
          "${modifier}+f" = "fullscreen toggle";

          "${modifier}+Left" = "move workspace to output left";
          "${modifier}+Right" = "move workspace to output right";

        } // per-workspace (key: ws: {
          "${modifier}+${key}" = "workspace ${ws}";
          "${modifier}+Ctrl+${key}" = "move container to workspace ${ws}";
        }) // per-direction (key: dir: {
          "${modifier}+${key}" = "focus ${dir}";
          "${modifier}+Ctrl+${key}" = "move ${dir}";
        });

        modes = { }; # remove the default resize mode

        input = {
          "type:keyboard" = {
            repeat_delay = "300";
            repeat_rate = "70";
          };
          "1:1:AT_Translated_Set_2_keyboard" = {
            xkb_options = "caps:escape";
          };
          "type:mouse" = {
            left_handed = "enabled";
          };
          "type:touchpad" = {
            dwt = "disabled";
            natural_scroll = "enabled";
            pointer_accel = "0.5";
            tap = "enabled";
          };
          "type:pointer" = {
            left_handed = "disabled";
            pointer_accel = "0.5";
          };
        };

        output = {
          "*" = {
            bg = "~/Documents/walls/WALL fill";
            adaptive_sync = "on";
          };

          # laptop monitor
          "Sharp Corporation 0x1420 0x00000000".pos = "1920 1440";
          # home monitor
          "BenQ Corporation BenQ G2420HD V7905125SL0".pos = "0 1440";
          # left work monitor
          "Dell Inc. DELL U2719D 5ZWQPS2" = {
            mode = "2560x1440@59.951Hz";
            pos = "0 0";
          };
          # right work monitor
          "Dell Inc. DELL U2719D 6N6LLS2" = {
            mode = "2560x1440@59.951Hz";
            pos = "2560 0";
          };
        };

        window.border = 1;
        floating.border = 1;

        startup = [
          {
            command = "/bin/sh -c '${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE=wayland; ${pkgs.systemd}/bin/systemd-notify --ready'";
            always = true;
          }
        ];

        # window-specific things
        window.commands = [
          {
            criteria.app_id = "dragon-drop";
            command = "sticky enable";
          }
          {
            criteria.app_id = "tdrop";
            command = "floating enable, resize set width 60ppt height 60ppt, move position center, sticky enable";
          }
        ];
      };
  };

  systemd.user.services.sway = {
    Unit = {
      Description = "SirCmpwn's Wayland window manager";
      Documentation = "man:sway(5)";

      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
      BindsTo = [ "graphical-session.target" ];
      Before = [ "graphical-session.target" ];
      PropagateReloadFrom = [ "graphical-session.target" ];
    };

    Service = {
      Slice = "session.slice";
      Type = "notify";
      NotifyAccess = "all"; # we use systemd-notify so we need to accept startup notifications from everyone
      ExecStart = "${cfg.package}/bin/sway";
      Environment = "PATH=/bin"; # swaywm uses execlp with "sh" sometimes; this should fix that
      TimeoutStopSec = 10;

      Restart = "on-failure";
      RestartSec = 1;

      ExecReload = [
        # This errors for some reason with '[common/ipc-client.c:87] Unable to receive IPC response'
        # so we need to suppress it
        "-${cfg.package}/bin/swaymsg reload"
      ];

      # TODO also need to unset in dbus?
      ExecStopPost = [
        "${pkgs.systemd}/bin/systemctl --user unset-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
        "${pkgs.systemd}/bin/systemctl --user stop graphical-session.target"
      ];
    };
  };
}
