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

    mafredri-zsh-async = { url = "github:mafredri/zsh-async"; flake = false; };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
        config = import ./assets/nixpkgs-config.nix;
      };

      forAllSystems = with nixpkgs.lib; genAttrs systems.flakeExposed;
    in
    {
      formatter = forAllSystems (s: (pkgsFor s).nixpkgs-fmt);
      packages = forAllSystems (s: {
        nixpkgs = pkgsFor s;
      });

      overlays.default = import ./pkgs;

      # temmie@wattle: XPS 13 =================================================

      # This is kinda rip atm since I'm not using the laptop for anything
      /*
      homeConfigurations."temmie@wattle" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "x86_64-linux";
        modules = [
          rec {
            home.username = "temmie";
            home.homeDirectory = "/home/${home.username}";
          }
          ./home-manager/temmie-wattle
        ];
        extraSpecialArgs = {
          inherit inputs;
          target = { kind = "home-manager"; user = "temmie"; host = "wattle"; };
          repo-root = "/home/temmie/src/github.com/ralismark/nixfiles";
        };
      };

      nixosConfigurations."wattle" = nixpkgs.lib.nixosSystem {
        pkgs = pkgsFor "x86_64-linux";
        modules = [
          inputs.nixos-hardware.nixosModules.dell-xps-13-9360
          inputs.impermanence.nixosModules.impermanence
          ./nixos/wattle
        ];
        specialArgs = {
          inherit inputs;
          target = { kind = "nixos"; host = "wattle"; };
          repo-root = "/home/temmie/src/github.com/ralismark/nixfiles";
        };
      };
      */

      # temmie@waratah: Framework 13 ==========================================

      homeConfigurations."temmie@waratah" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "x86_64-linux";
        modules = [
          rec {
            home.username = "temmie";
            home.homeDirectory = "/home/temmie";
          }
          ./home-manager/temmie-waratah
        ];
        extraSpecialArgs = {
          inherit inputs;
          target = { kind = "home-manager"; user = "temmie"; host = "waratah"; };
          repo-root = "/home/temmie/src/github.com/ralismark/nixfiles";
        };
      };

      nixosConfigurations."waratah" = nixpkgs.lib.nixosSystem {
        pkgs = pkgsFor "x86_64-linux";
        modules = [
          inputs.nixos-hardware.nixosModules.framework-13-7040-amd
          inputs.impermanence.nixosModules.impermanence
          ./nixos/waratah
        ];
        specialArgs = {
          inherit inputs;
          target = { kind = "nixos"; host = "waratah"; };
          repo-root = "/home/temmie/src/github.com/ralismark/nixfiles";
        };
      };

      # temmie@Temmies-MacBook-Pro.local: Canva ===============================

      homeConfigurations."temmie@Temmies-MacBook-Pro.local" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor "x86_64-darwin";
        modules = [
          rec {
            home.username = "temmie";
            home.homeDirectory = "/Users/temmie";
          }
          ./home-manager/temmie-canva
        ];
        extraSpecialArgs = {
          inherit inputs;
          target = { kind = "home-manager"; user = "temmie"; host = "Temmies-MacBook-Pro.local"; };
          repo-root = "/Users/temmie/src/github.com/ralismark/nixfiles";
        };
      };

    };
}
