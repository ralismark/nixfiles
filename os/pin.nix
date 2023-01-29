{ config
, inputs
, ...
}:
{
  # match nixpkgs
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # NOTE /etc/nix/path is a concept we made up
  environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;
  nix.nixPath = [ "/etc/nix/path" ];

  # match config
  environment.variables.NIXPKGS_CONFIG = "/etc/nix/nixpkgs-config.nix";
  environment.etc."nix/nixpkgs-config.nix".source = ../nixpkgs-config.nix;
}
