{ pkgs, ... }:
{
  home.packages = with pkgs; [
    clippy
    # TODO why do we need gcc?
    gcc
    rust-analyzer
    rustc
  ];

  # TODO do we wanna use a persistent place for cache e.g. /var/tmp/ ?

  programs.cargo = {
    enable = true;
    settings = {
      # make cargo clone with git cli, not libgit, so that ssh auth/etc work
      net.git-fetch-with-cli = true;
      # use temporary global build dir to use less disk
      build.target-dir = "/tmp/cargo-target";
    };
  };

  programs.sccache = {
    enable = true;
    enableCargoIntegration = true;
    settings.cache.disk.dir = "/tmp/sccache";
  };
}
