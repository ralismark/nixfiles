{ pkgs, ... }:
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

  startup = ''
    if [[ $XDG_VTNR -eq 1 ]]; then
      ${launch-wm "sway.service"}
    fi
  '';
in
{
  imports = [
    ./alacritty.nix
    ./mako.nix
    ./rofi.nix
    ./sway.nix
    ./waybar.nix

    ../../modules/xdg-portal-wlr.nix
    ../../modules/xdg-portal-gtk.nix
  ];

  systemd.user.targets.graphical-session = {
    # copied from systemd's graphical-session.target, because home-manager doesn't support drop-ins
    Unit = {
      Description = "Current graphical user session";
      Documentation = "man:systemd.special(7)";
      Requires = [ "basic.target" ];
      RefuseManualStart = true;
      StopWhenUnneeded = true;

      # added
      DefaultDependencies = false; # don't add After= for each Wants/Requires
      Conflicts = "shutdown.target";
      Before = "shutdown.target";
    };
  };

  # Startup ===================================================================

  programs.bash.enable = true;
  # See <https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html#implementation>
  programs.bash.profileExtra = startup;
  programs.zsh.profileExtra = startup;

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

  xdg.portal = {
    enable = true;
    config.common.default = [ "wlr" "gtk" ];

    gtk.enable = true;
    wlr.enable = true;
    wlr.settings.screencast = {
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
  };
}
