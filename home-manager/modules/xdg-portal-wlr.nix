{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.xdg.portal.wlr;
  pkg = pkgs.xdg-desktop-portal-wlr;
  settingsFormat = pkgs.formats.ini { };
  configFile = settingsFormat.generate "xdg-desktop-portal-wlr.ini" cfg.settings;
in
{
  options.xdg.portal.wlr = {
    enable = lib.mkEnableOption (lib.mdDoc ''
      desktop portal for wlroots-based desktops

      This will add the `xdg-desktop-portal-wlr` package into
      the {option}`xdg.portal.extraPortals` option, and provide the
      configuration file
    '');

    settings = lib.mkOption {
      description = lib.mdDoc ''
        Configuration for `xdg-desktop-portal-wlr`.

        See `xdg-desktop-portal-wlr(5)` for supported
        values.
      '';

      type = lib.types.submodule {
        freeformType = settingsFormat.type;
      };

      default = { };

      # Example taken from the manpage
      example = lib.literalExpression ''
        {
          screencast = {
            output_name = "HDMI-A-1";
            max_fps = 30;
            exec_before = "disable_notifications.sh";
            exec_after = "enable_notifications.sh";
            chooser_type = "simple";
            chooser_cmd = "''${pkgs.slurp}/bin/slurp -f %o -or";
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    assertions = [
      {
        assertion = config.xdg.portal.enable;
        message = "xdg.portal.enable must be true to use wlr portal";
      }
    ];

    home.packages = [ pkg ];
    xdg.portal.extraPortals = [ pkg ];

    xdg.configFile."xdg-desktop-portal-wlr/config".source = settingsFormat.generate "xdg-desktop-portal-wlr.ini" cfg.settings;

  };
}
