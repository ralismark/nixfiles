{ pkgs, ... }:
{
  imports = [
    ./alacritty.nix
    ./mako.nix
    ./rofi.nix
    ./sway.nix
    ./waybar.nix
    ./hyprland.nix
  ];

  # Startup ===================================================================

  programs.bash.enable = true;
  programs.bash.profileExtra =
    let
      launch-wm = unit: ''
        if ! ${pkgs.systemd}/bin/systemctl -q --user is-active ${unit}; then
          # Import vars needed to start ${unit}
          ${pkgs.systemd}/bin/systemctl --user import-environment XDG_SEAT XDG_SESSION_CLASS XDG_SESSION_ID XDG_SESSION_TYPE XDG_VTNR
          exec ${pkgs.systemd}/bin/systemctl --user start --wait ${unit}
        else
          printf '\e[31;1m%s\e[0m\n' '!!! ${unit} is already running !!!' >&2
        fi
      '';
      unit = "graphical-host.service";
    in
    ''
      if [[ $XDG_VTNR -eq 1 ]]; then
        ${launch-wm "sway.service"}
      elif [[ $XDG_VTNR -eq 2 ]]; then
        ${launch-wm "hyprland.service"}
      fi
    '';

  # Misc ======================================================================

  systemd.user.services.nm-applet = {
    Unit = {
      Description = "Network manager applet";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
