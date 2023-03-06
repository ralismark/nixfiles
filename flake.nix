{
  description = "Temmie's Nix Things";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };

    mafredri-zsh-async = { url = "github:mafredri/zsh-async"; flake = false; };
    hyprland.url = "github:hyprwm/Hyprland";
    nix-index-database.url = "github:Mic92/nix-index-database";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , home-manager
    , ...
    }@inputs:
    let
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
        config = import ../assets/nixpkgs-config.nix;
      };

      # Extra params to pass to modules
      common-cfg = { lib, ... }: {
        _module.args = {
          inherit inputs;
        };
      };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = pkgsFor system;
      in
      {
        formatter = pkgs.nixpkgs-fmt;
      }) //
    {
      overlays.default = nixpkgs.lib.composeManyExtensions [
        (import ./pkgs)
        inputs.hyprland.overlays.default
      ];

      # temmie@wattle: XPS 13 =================================================

      homeConfigurations."temmie@wattle" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "x86_64-linux";
        modules = [
          common-cfg
          ({ config, ... }: with config; {
            home.username = "temmie";
            home.homeDirectory = "/home/${home.username}";
            _module.args.repo-root = "${home.homeDirectory}/src/github.com/ralismark/nixfiles";
          })
          ./hm
        ];
      };

      nixosConfigurations."wattle" = nixpkgs.lib.nixosSystem {
        pkgs = pkgsFor "x86_64-linux";
        modules = [
          common-cfg
          ({
            _module.args.repo-root = "/home/temmie/src/github.com/ralismark/nixfiles";
          })
          inputs.nixos-hardware.nixosModules.dell-xps-13-9360
          inputs.impermanence.nixosModules.impermanence
          ./os
        ];
      };

      # =======================================================================

    };
}
