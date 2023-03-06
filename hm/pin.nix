{ config
, inputs
, ...
}:
{
  # don't declare nix.package since that's managed by nixos

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
  #           config = import "''${nixfiles}/assets/nixpkgs-config.nix";
  #         });
  #       };
  #     }
  #   '';
  # };

  # NOTE ~/.config/nix/path is a concept we made up
  xdg.configFile."nix/path/nixpkgs".source = inputs.nixpkgs;
  home.sessionVariables.NIX_PATH = "${config.xdg.configHome}/nix/path\${NIX_PATH:+:}\$NIX_PATH"; # TODO this isn't passed to sway?

  # match config
  home.sessionVariables.NIXPKGS_CONFIG = "${config.xdg.configHome}/nixpkgs/config.nix";
  xdg.configFile."nixpkgs/config.nix".source = ../assets/nixpkgs-config.nix;

  # pass overlays
  xdg.configFile."nixpkgs/overlays.nix".text = ''
    [(import ${./..}).overlays.default]
  '';
}
