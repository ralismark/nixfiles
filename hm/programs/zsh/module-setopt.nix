{ config, lib, ... }:
with lib;
let
  cfg = config.programs.zsh.options;
in
{
  options.programs.zsh.options = mkOption {
    type = types.attrsOf types.bool;
    default = { };
    description = "Options to set with setopt/unsetopt. See man zshoptions(1).";
  };

  config.programs.zsh.initExtra =
    concatStringsSep "\n" (mapAttrsToList (k: v: "${if v then "setopt" else "unsetopt"} ${k}") cfg);
}
