{ config, pkgs, ... }:
{
  # https://github.com/Alexays/Waybar/wiki/Configuration
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "left";
      spacing = 0; # we do spacing in CSS to handle hidden items properly
      width = 32;

      modules-left = [ "pulseaudio" "tray" ];
      modules-center = [ "sway/workspaces" ];
      modules-right = [ "backlight" "battery" "clock" ];

      backlight = {
        format = "☀\n{percent}";
        format-baseline = "";
        on-click = "${pkgs.brightnessctl}/bin/brightnessctl set 100%";
        states = {
          hidden = 100;
          visible = 99;
        };
      };

      battery = {
        adapter = "AC";
        bat = "BAT0";
        format = "{icon}\n{capacity}";
        format-charging = "🔌\n{capacity}";
        format-icons = [ "🌑" "🌘" "🌗" "🌖" "🌕" "🌕" ];
        format-plugged = "🔌\n{capacity}";
        states = {
          good = 100;
          low = 20;
        };
        tooltip-format = "{capacity}% {timeTo}";
      };

      clock = {
        format = "{:%I\n%M}";
        tooltip = true;
        tooltip-format = "{:%a, %d. %b  %H:%M  %F}";
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "";
          deactivated = "";
        };
      };

      memory = {
        format = "mem\n{percentage}\n{used}";
      };

      pulseaudio = {
        format-icons = [ "🔈" "🔉" "🔊" ];
        format = "{icon}\n{volume}";
        format-bluetooth = "{icon}\n{volume}";
        format-muted = "🔇\n--";
        on-click = "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
        on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
        scroll-step = 1;
      };

      "sway/workspaces" = {
        all-outputs = true;
        disable-scroll = true;
        format = "{name}";
        persistent_workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
          "6" = [ ];
          "7" = [ ];
          "8" = [ ];
          "9" = [ ];
          "10" = [ ];
        };
      };

      "wlr/workspaces" = {
        all-outputs = true;
        sort-by-number = true;
        format = "{name}";
      };

      tray = {
        spacing = 8;
      };
    };

    style = ''
      @keyframes blink {
        to {
          background-color: transparent;
        }
      }

      window#waybar {
        background: transparent;
        color: #fdf6e3;
        font-family: "Droid Sans Mono", "Blobmoji";
        font-size: 14px;
      }

      .modules-left > * > *:not(.hidden),
      .modules-right > * > *:not(.hidden) {
        margin: 4px 0;
      }
      .hidden { font-size: 0.01px; } /* this still leaves some space but it's as good as we'll get */

      #battery { color: #859900; }
      #battery.low:not(.charging) {
        color: red;
        background-color: orange;

        animation-name: blink;
        animation-duration: 3s;
        animation-timing-function: ease-in-out;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      #workspaces > button:nth-child(1)  { border-color: #37b7ec; }
      #workspaces > button:nth-child(2)  { border-color: #46b9d4; }
      #workspaces > button:nth-child(3)  { border-color: #53bbba; }
      #workspaces > button:nth-child(4)  { border-color: #63bb9e; }
      #workspaces > button:nth-child(5)  { border-color: #78ba83; }
      #workspaces > button:nth-child(6)  { border-color: #96b56c; }
      #workspaces > button:nth-child(7)  { border-color: #b3ae60; }
      #workspaces > button:nth-child(8)  { border-color: #cda55e; }
      #workspaces > button:nth-child(9)  { border-color: #e39b63; }
      #workspaces > button:nth-child(10) { border-color: #f6906d; }

      #workspaces > button {
        min-height: 70px;
        padding: 0;
        margin: 2px 0;
        border-left: 2px solid rgba(127, 127, 127, 0.5);
        color: transparent;
      }
        #workspaces > button:hover {
          box-shadow: inherit;
          text-shadow: inherit;
          background: #1a1a1a;
          color: #fdf6e3;
        }
        #workspaces > button.persistent,
        #workspaces > button:not(.current_output):not(.persistent) {
          border-color: transparent;
        }
        #workspaces > button.visible.current_output,
        #workspaces > button.visible {
          color: #fdf6e3;
        }
        #workspaces > button.current_output.focused,
        #workspaces > button.active {
          background: linear-gradient(to right, #808080, transparent);
          color: #fdf6e3;
        }

      #pulseaudio { color: #268bd2; }
      #backlight { color: #b58900; }
      #memory { color: #2aa198; }
      #temperature { color: #b58900; }
      #cpu { color: #6c71c4; }
    '';
  };

  xdg.configFile."waybar/config".onChange = ''
    ${pkgs.systemd}/bin/systemctl --user try-restart waybar.service
  '';
}
