{ config, pkgs, ... }:
let
  inherit (pkgs) lib;
in
{
  home.packages = with pkgs; [
    cargo
    clippy
    gcc
    rust-analyzer
    rustc
  ];

  home.file.".cargo/config.toml".text = lib.generators.toINI {} {
    # make cargo clone with git cli, not libgit, so that ssh auth/etc work
    net.git-fetch-with-cli = true;
  };
}
