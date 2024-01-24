{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.xdg.portal.gtk;
  pkg = pkgs.xdg-desktop-portal-gtk;
in
{
  options.xdg.portal.gtk = {
    enable = lib.mkEnableOption "Gtk implementation of xdg-desktop-portal";
  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = config.xdg.portal.enable;
        message = "xdg.portal.enable must be true to use gtk portal";
      }
    ];

    home.packages = [ pkg ];
    xdg.portal.extraPortals = [ pkg ];

  };
}
