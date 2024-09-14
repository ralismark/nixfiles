{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.home.bin;
in
{
  options.home.bin = mkOption {
    # TODO don't create temporary file?
    type = types.attrsOf (types.submodule (
      { name, config, ... }: {
        options = {
          text = mkOption {
            type = types.str;
            example = "cd $(mktemp -d)";
            description = "Shell script content";
          };

          source = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "\${home.homeDirectory}/bin/do_thing";
            description = "Path to link";
          };
        };

        config = mkMerge [
          (mkIf (config.source != null) {
            text = ''
              #!/bin/sh
              exec "${config.source}" "$@"
            '';
          })
        ];
      }
    ));
    default = { };
    description = "Things to put in $PATH";
  };

  config.home.packages = mkIf (cfg != {}) [
    (hiPrio (pkgs.runCommandLocal "home-bin" { } ''
      mkdir -p $out/bin
      ${concatStringsSep "\n"
        (mapAttrsToList
          (name: c: "cp ${pkgs.writeScript "script" c.text} $out/bin/${escapeShellArg name}")
          cfg)}
    ''))
  ];
}
