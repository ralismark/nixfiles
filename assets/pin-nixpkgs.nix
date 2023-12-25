{ config
, lib
, inputs
, modulesTarget
, ...
}@args:
let
  # 2023-11-29: I tried pinning github:nixos/nixpkgs/nixpkgs-unstable to this
  # repo's nixpkgs commit, but it turns out that the flake registry only works
  # with *indirect* references, and not github:...

  nixpkgs-flake-lock = {
    type = "github";
    owner = "nixos";
    repo = "nixpkgs";
    inherit (inputs.nixpkgs) lastModified narHash rev;
  };
in
import ../lib/variants-config.nix modulesTarget {

  home-manager = {
    # match nixpkgs
    nix.registry.nixpkgs.to = nixpkgs-flake-lock;

    # NOTE ~/.config/nix/path is a concept we made up
    xdg.configFile."nix/path/nixpkgs".source = inputs.nixpkgs;
    home.sessionVariables.NIX_PATH = "${config.xdg.configHome}/nix/path\${NIX_PATH:+:}\$NIX_PATH"; # TODO this isn't passed to sway?

    # match config
    home.sessionVariables.NIXPKGS_CONFIG = "${config.xdg.configHome}/nixpkgs/config.nix";
    xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;

    # pass overlays
    # lib.cleanSource to make use of nixpkgs not complain about dirty sources
    xdg.configFile."nixpkgs/overlays/pin.nix".text = ''
      (import ${lib.cleanSource ../.}).overlays.default
    '';

    # make home-manager command available
    programs.home-manager.enable = true;

    # use nixfiles for home-manager
    xdg.configFile."home-manager/flake.nix".source =
      lib.mkIf (args ? repo-root)
        (config.lib.file.mkOutOfStoreSymlink "${args.repo-root}/flake.nix");
  };

  nixos = {
    # match nixpkgs
    nix.registry.nixpkgs.to = nixpkgs-flake-lock;

    # NOTE /etc/nix/path is a concept we made up
    environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;
    nix.nixPath = [ "/etc/nix/path" ];

    # match config
    environment.variables.NIXPKGS_CONFIG = "/etc/nix/nixpkgs-config.nix";
    environment.etc."nix/nixpkgs-config.nix".source = ./nixpkgs-config.nix;

    # use nixfiles for nixos-rebuild
    environment.etc."nixos/flake.nix".source =
      lib.mkIf (args ? repo-root)
        ("${args.repo-root}/flake.nix");
  };

}
