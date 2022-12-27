{
  description = "Temmie's Nix Things";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # or "nixpkgs/nixos-22.05"
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database.url = "github:Mic92/nix-index-database";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import ./nixpkgs/overlay.nix) ];
        config = import ./nixpkgs/config.nix;
      };
      extras =
        let
          lock = builtins.fromJSON (builtins.readFile ./flake.lock);
        in
        {
          inherit inputs lock;
          lock-inputs =
            assert pkgs.lib.asserts.assertMsg (lock.version == 7) "flake.lock version has changed!";
            builtins.mapAttrs
              (_: n: lock.nodes.${n})
              lock.nodes.${lock.root}.inputs;
        };
    in
    rec {
      formatter.${system} = pkgs.nixpkgs-fmt;

      # Home Manager ============================================================

      # NixOS ===================================================================

      # =========================================================================
    };
}
