{ config
, inputs
, ...
}:
{
  # match nixpkgs
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  # nix.registry.nixpkgs = {
  #   exact = true;
  #   flake = pkgs.writeTextDir "flake.nix" ''
  #     {
  #       description = "A collection of packages for the Nix package manager";
  #
  #       inputs = {
  #         nixpkgs.url = "${inputs.nixpkgs}";
  #         nixfiles.url = "${inputs.self}";
  #       };
  #
  #       outputs = { self, nixpkgs, nixfiles }:
  #       let
  #         forAllSystems = with nixpkgs.lib; genAttrs systems.flakeExposed;
  #       in
  #       nixpkgs // {
  #         legacyPackages = forAllSystems (system: import nixpkgs {
  #           inherit system;
  #           overlays = [ nixfiles.overlays.default ];
  #           config = import "''${nixfiles}/nixpkgs-config.nix";
  #         });
  #       };
  #     }
  #   '';
  # };

  # NOTE /etc/nix/path is a concept we made up
  environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;
  nix.nixPath = [ "/etc/nix/path" ];

  # match config
  environment.variables.NIXPKGS_CONFIG = "/etc/nix/nixpkgs-config.nix";
  environment.etc."nix/nixpkgs-config.nix".source = ../nixpkgs-config.nix;
}
