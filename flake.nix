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

    hyprland.url = "github:hyprwm/Hyprland";
    nix-index-database.url = "github:Mic92/nix-index-database";

    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , nixos-hardware
    , impermanence
    , hyprland
    , ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (import ./pkgs)
          hyprland.overlays.default
        ];
        config = import ./nixpkgs-config.nix;
      };

      # Extra params to pass to modules
      extra-args = {
        _module.args = rec {
          inherit inputs;

          lock = builtins.fromJSON (builtins.readFile ./flake.lock);

          lock-inputs =
            assert pkgs.lib.asserts.assertMsg (lock.version == 7) "flake.lock version has changed!";
            builtins.mapAttrs
              (_: n: lock.nodes.${n})
              lock.nodes.${lock.root}.inputs;
        };
      };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;
      inherit pkgs;

      # temmie@wattle: XPS 13 =================================================

      homeConfigurations."temmie@wattle" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          extra-args
          ({ config, ... }: with config; {
            home.username = "temmie";
            home.homeDirectory = "/home/${home.username}";
            _module.args.repo-root = "${home.homeDirectory}/src/github.com/ralismark/nixfiles";
          })
          ./hm/home.nix
        ];
      };

      nixosConfigurations.wattle = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        modules = [
          extra-args
          (rec {
            _module.args.repo-root = "/home/temmie/src/github.com/ralismark/nixfiles";
          })
          nixos-hardware.nixosModules.dell-xps-13-9360
          impermanence.nixosModules.impermanence
          ./os/configuration.nix
        ];
      };

      # =======================================================================

    };
}
