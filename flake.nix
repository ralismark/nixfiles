{
  description = "Temmie's Nix Things";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # or "nixpkgs/nixos-22.05"
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    nix-index-database.url = "github:Mic92/nix-index-database";
  };

  outputs = { nixpkgs, home-manager, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (import ./nixpkgs)
          hyprland.overlays.default
        ];
        config = import ./nixpkgs-config.nix;
      };
      extras =
        rec {
          inherit inputs;
          lock = builtins.fromJSON (builtins.readFile ./flake.lock);
          lock-inputs =
            assert pkgs.lib.asserts.assertMsg (lock.version == 7) "flake.lock version has changed!";
            builtins.mapAttrs
              (_: n: lock.nodes.${n})
              lock.nodes.${lock.root}.inputs;
        };
    in
    rec {
      formatter.${system} = pkgs.nixpkgs-fmt;

      np = pkgs;

      # Home Manager ============================================================

      homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./hm/home.nix ];

        extraSpecialArgs = extras;
      };

      # So that `nix run` is sufficient to rebuild
      apps.${system}.default = {
        type = "app";
        program = "${homeConfigurations.me.activationPackage}/activate";
      };
      packages.${system}.default = homeConfigurations.me.activationPackage;

      # NixOS ===================================================================

      # =========================================================================
    };
}
