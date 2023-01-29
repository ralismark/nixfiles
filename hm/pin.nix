{ config
, inputs
, ...
}:
{
  # don't declare nix.package since that's managed by nixos

  # match nixpkgs
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # NOTE ~/.config/nix/path is a concept we made up
  xdg.configFile."nix/path/nixpkgs".source = inputs.nixpkgs;
  home.sessionVariables.NIX_PATH = "${config.xdg.configHome}/nix/path\${NIX_PATH:+:}\$NIX_PATH"; # TODO this isn't passed to sway?

  # match config
  home.sessionVariables.NIXPKGS_CONFIG = "${config.xdg.configHome}/nixpkgs/config.nix";
  xdg.configFile."nixpkgs/config.nix".source = ../nixpkgs-config.nix;
}
