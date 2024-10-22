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
    systemd.enable = false; # We do our own custom systemd integration

    checkConfig = false; # Check fails because we use ~/Documents/walls/WALL as wallpaper
    config =
      let
        # we use systemd to move the processes out of sway.service
        # TODO why double systemd-run?
        exec = "${pkgs.systemd}/bin/systemd-run --user -- ${pkgs.systemd}/bin/systemd-run --user --scope --slice=app-graphical.slice --";

        screenshot = region-cmd: let
          script = ''
            #!${pkgs.bash}/bin/bash

            out="$(${pkgs.coreutils}/bin/date +'/tmp/screenshot-%Y%m%d-%H%M%S.png')"
            {
              ${region-cmd}
            } | ${pkgs.grim}/bin/grim -g- "$out" && {
              ${pkgs.wl-clipboard}/bin/wl-copy -t image/png < "$out"
              ${pkgs.xdragon}/bin/dragon "$out"
            }
          '';
        in "exec ${exec} ${pkgs.writeScript "sway-screenshot" script}";

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
          XF86AudioPlay = "exec ${pkgs.pulseaudio}/bin/pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          # XF86AudioPlay = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          # XF86AudioNext = "exec ${pkgs.playerctl}/bin/playerctl next";
          # XF86AudioPrev = "exec ${pkgs.playerctl}/bin/playerctl previous";

          XF86MonBrightnessDown = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";
          XF86MonBrightnessUp = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%+";

          Print = screenshot "${pkgs.slurp}/bin/slurp";
          "Shift+Print" = screenshot ''
            ${cfg.package}/bin/swaymsg --raw -t get_tree |
              ${pkgs.jq}/bin/jq -r '
                recurse(.nodes[]) |
                select(.focused) |
                @text "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"
              '
          '';

          # Layout Management --------------------------------------------------

          "${modifier}+a" = "layout toggle all";
          "${modifier}+s" = "sticky toggle";
          "${modifier}+d" = "floating toggle";
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
            xkb_file = "${./keymap.xkb}";
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

          # laptop monitor (xps 13)
          "Sharp Corporation 0x1420 Unknown".pos = "4000 2000";
          # laptop monitor (framework 13)
          "BOE 0x0BCA Unknown" = {
            scale = "1.333333";
            pos = "4000 2000";
          };
          "Microstep MSI MP275Q PC3M264600588".pos = "1440 2000";
        };

        window.border = 1;
        floating.border = 1;

        startup = [
          {
            command = let
              script = ''
                #!/bin/sh
                ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE=wayland _JAVA_AWT_WM_NONREPARENTING=1
                ${pkgs.systemd}/bin/systemd-notify --ready
                ${pkgs.systemd}/bin/systemctl --user start sway-session.target
              '';
              in builtins.toString (pkgs.writeScript "sway-ready-systemd" script);
            always = true;
          }
        ];

        # window-specific things
        window.commands = [
          {
            criteria.app_id = "dragon";
            command = "sticky enable";
          }
          {
            criteria.app_id = "tdrop";
            command = "floating enable, resize set width 60ppt height 60ppt, move position center, sticky enable";
          }
        ];
      };
  };

  systemd.user.targets.sway-session = {
    # need this because graphical-session.target and xdg-desktop-autostart.target both have RefuseManualStart=true
    Unit = {
      Description = "graphical-session.target for sway";
      BindsTo = [ "graphical-session.target" "xdg-desktop-autostart.target" ];
    };
  };

  systemd.user.services.sway = {
    Unit = {
      Description = "SirCmpwn's Wayland window manager";
      Documentation = "man:sway(5)";

      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "sway-session.target" "graphical-session.target" ];
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
        "${pkgs.systemd}/bin/systemctl --user unset-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE _JAVA_AWT_WM_NONREPARENTING"
        "${pkgs.systemd}/bin/systemctl --user stop graphical-session.target"
      ];
    };
  };
}
