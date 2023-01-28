{ config, pkgs, ... }:
{
  imports = [
    ../modules/hyprland.nix
  ];

  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.config =
    let
      mod = "SUPER";
    in
    {
      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor = ",preferred,auto,1";

      # See https://wiki.hyprland.org/Configuring/Keywords/ for more

      # For all categories, see https://wiki.hyprland.org/Configuring/Variables/

      input = {
        # keyboard
        repeat_rate = 70;
        repeat_delay = 300;

        follow_mouse = 1;

        # touchpad
        sensitivity = 0.5;
        touchpad.disable_while_typing = false;
        touchpad.natural_scroll = true;
      };

      "device:at-translated-set-2-keyboard".kb_options = "caps:escape";

      general = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more

        gaps_in = 3;
        gaps_out = 6;
        border_size = 1;

        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        layout = "dwindle";
      };

      misc = {
        disable_hyprland_logo = true;
        no_vfr = false; # Variable FrameRate improves battery at the cost of graphics
        mouse_move_enables_dpms = true;
        disable_autoreload = true; # autoreload doesn't detect changed symlink; we do hyprctl reload via systemd unit
      };

      decoration = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more

        rounding = 0;
        blur = true;
        blur_size = 3;
        blur_passes = 1;
        blur_new_optimizations = true;

        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };

      animation = {
        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

        animation = [
          "windows, 1, 3, default, popin 80%"
          "windowsOut, 1, 3, default, popin 95%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 1, default, fade"
        ];
      };

      dwindle = {
        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # you probably want this
      };

      master = {
        # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        new_is_master = true;
      };

      gestures = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        workspace_swipe = true;
        workspace_swipe_distance = 800;
        workspace_swipe_cancel_ratio = 0.3;
      };

      exec-once = [
        "${pkgs.swaybg}/bin/swaybg -o '*' -i ~/Documents/walls/WALL -m fill"
      ];

      # Example windowrule v1
      # windowrule = [ "float, ^(kitty)$" ]
      # Example windowrule v2
      # windowrulev2 = [ "float,class:^(kitty)$,title:^(kitty)$" ]
      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

      # See https://wiki.hyprland.org/Configuring/Keywords/ for more
      bind =
        let

          # we use systemd to move the processes out of sway.service
          # TODO why double systemd-run?
          exec = "${pkgs.systemd}/bin/systemd-run --user -- ${pkgs.systemd}/bin/systemd-run --user --scope --slice=app-graphical.slice";

          per-workspace = fn:
            # key name
            fn "1" "1" ++
            fn "2" "2" ++
            fn "3" "3" ++
            fn "4" "4" ++
            fn "5" "5" ++
            fn "6" "6" ++
            fn "7" "7" ++
            fn "8" "8" ++
            fn "9" "9" ++
            fn "0" "10";

          per-direction = fn:
            # key dir
            fn "H" "l" ++
            fn "J" "d" ++
            fn "K" "u" ++
            fn "L" "r";
        in
        [
          # ref: https://wiki.hyprland.org/Configuring/Binds/
          "${mod}, Return, exec, ${exec} ${config.programs.alacritty.package}/bin/alacritty"
          "${mod}, W, killactive"
          "${mod}, Space, exec, ${exec} ${config.programs.rofi.package}/bin/rofi -show combi"

          # "${mod}, Q, exec, kitty"
          # "${mod}, C, killactive, "
          # "${mod}, M, exit, "
          # "${mod}, E, exec, dolphin"
          # "${mod}, V, togglefloating, "
          # "${mod}, R, exec, wofi --show drun"
          # "${mod}, P, pseudo, # dwindle"
          # "${mod}, J, togglesplit, # dwindle"

          "${mod}, Left, movecurrentworkspacetomonitor, l"
          "${mod}, Down, movecurrentworkspacetomonitor, d"
          "${mod}, Up, movecurrentworkspacetomonitor, u"
          "${mod}, Right, movecurrentworkspacetomonitor, r"
        ] ++ per-direction (key: dir: [
          "${mod}, ${key}, movefocus, ${dir}"
          "${mod} CTRL, ${key}, movewindow, ${dir}"
        ]) ++ per-workspace (key: ws: [
          "${mod}, ${key}, workspace, ${ws}"
          "${mod} CTRL, ${key}, movetoworkspacesilent, ${ws}"
        ]);

      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "${mod}, mouse:272, movewindow"
        "${mod}, mouse:273, resizewindow"
      ];
    };
}
