{ config, pkgs, ... }:
with config;
{
  imports = [
    ./alacritty.nix
    ./mako.nix
    ./rofi.nix
    ./sway.nix
    ./waybar.nix
  ];

  home.file.".profile".text = ''
    if [[ $XDG_VTNR -eq 1 ]]; then
      if ! ${pkgs.systemd}/bin/systemctl -q --user is-active sway.service; then
        # Import vars needed to start sway
        ${pkgs.systemd}/bin/systemctl --user import-environment XDG_SEAT XDG_SESSION_CLASS XDG_SESSION_ID XDG_SESSION_TYPE XDG_VTNR
        exec ${pkgs.systemd}/bin/systemctl --user start --wait sway
      else
        printf '\e[31;1m%s\e[0m\n' '!!! sway.service is already running !!!' >&2
      fi
    fi
  '';
}
