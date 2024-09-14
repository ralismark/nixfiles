{ lib, pkgs, config, ... }:
let
  format = pkgs.formats.toml {};
  cfg = config.programs.cargo;
in
{
  options.programs.cargo = {
    enable = lib.mkEnableOption "cargo, the rust package manager and build system";
    package = lib.mkPackageOption pkgs "cargo" { };
    settings = lib.mkOption {
      type = format.type;
      default = {};
      description = lib.mdDoc ''
        Configuration for cargo (`.cargo/config.toml`), see
        <https://doc.rust-lang.org/cargo/reference/config.html#configuration-keys>
        for supported values.
      '';
      example = lib.literalExpression ''
        {
          net.git-fetch-with-cli = true;
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.cargo pkgs.rustfmt ];
    home.file.".cargo/config.toml".source = format.generate "cargo-config.toml" cfg.settings;
  };
}
