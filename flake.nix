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
      repo-root = "/home/temmie/src/github.com/ralismark/nixfiles"; # !!! The physical location this repo is cloned to

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
          inherit inputs repo-root;

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

      # Home Manager ============================================================

      homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          extra-args
          ./hm/home.nix
        ];
      };

      # NixOS ===================================================================

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        modules = [
          extra-args
          nixos-hardware.nixosModules.dell-xps-13-9360
          impermanence.nixosModules.impermanence
          ./os/configuration.nix
        ];
      };

      # =========================================================================

      # So that `nix run` is sufficient to rebuild home manager
      # TODO make a home-grown hm-rebuild like nixos-rebuild that can differentiate between systems <2023-01-22>
      apps.${system}.default = {
        type = "app";
        program = "${self.homeConfigurations.me.activationPackage}/activate";
      };
      packages.${system}.default = self.homeConfigurations.me.activationPackage;
    };
}
