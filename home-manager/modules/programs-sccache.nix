{ lib, pkgs, config, ... }:
let
  cfg = config.programs.sccache;
  format = pkgs.formats.toml {};
in
{
  options.programs.sccache = {
    enable = lib.mkEnableOption "sccache";

    enableCargoIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to integrate with cargo";
    };

    settings = lib.mkOption {
      type = format.type;
      default = {};
      description = lib.mdDoc ''
        Configuration for sccache. See
        <https://github.com/mozilla/sccache/blob/main/docs/Configuration.md>
        for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.sccache ];
    xdg.configFile."sccache/config" = {
      source = format.generate "sccache-config" cfg.settings;

      # TODO this is not completely robust e.g. different server port, env vars, etc.
      onChange = ''
        ${pkgs.sccache}/bin/sccache --stop-server >/dev/null 2>/dev/null || true
      '';
    };

    programs.cargo.settings = lib.mkIf cfg.enableCargoIntegration {
      build.rustc-wrapper = "${pkgs.sccache}/bin/sccache";
    };
  };
}
