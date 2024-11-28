{ config
, inputs
, lib
, pkgs
, ...
}:
with config;
let
  pkgsFile = pkgs.callPackage ../../lib/attrs-file.nix { };
in {
  imports = [
    ../modules/home-bin.nix

    ../shared/programs-git.nix
    ../shared/programs-zsh
    ../shared/toolchains-go.nix
    ../shared/toolchains-k8s.nix
  ];

  # Installed =================================================================

  home.bin =
    let
      micro = "${home.homeDirectory}/src/github.com/ralismark/micro";
    in {
      vim.source = "${home.homeDirectory}/src/github.com/ralismark/vimfiles/result/bin/vim";
      vim-manpager.source = "${home.homeDirectory}/src/github.com/ralismark/vimfiles/result/bin/vim-manpager";
      ",".source = "${micro}/nixpkgs-run";
      ",,".source = "${micro}/nixpkgs-shell";
      ",?".source = "${micro}/nixpkgs-where";
    };

  home.packages = lib.flatten [
    (pkgsFile {
      keys = ./installed-packages.txt;
      pkgs = pkgs;
    })
  ];

  # Module Additions ==========================================================

  programs.git = let
    canva-org = "org-2562356";
  in {
    # we want to be explicit when interacting with github which identity we are

    # canva identity
    identity.canva = {
      origins = [ "${canva-org}@github.com:*/**" ];
      userName = "Temmie Yao";
      userEmail = "temmie@canva.com";
    };
    extraConfig.url."${canva-org}@github.com:Canva".insteadOf = [
      "https://github.com/Canva"
      "https://github.com/canva"
      "git@github.com:Canva"
      "git@github.com:canva"
    ];

    # personal github account
    identity.ralismark-github = {
      origins = [ "github-ralismark:*/**" ];
    };

    extraConfig = {
      core.untrackedCache = true;
      core.fsmonitor = true;
    };
  };

  programs.zsh = {
    initExtra = ''
      # escape hatch for canva-specific stuff
      source ~/.zshrc.local
    '';
  };

  # Nix =======================================================================

  programs.home-manager.enable = true;

  # nix-index
  home.file.".cache/nix-index/files".source = inputs.nix-index-database.packages.${nixpkgs.system}.nix-index-database;
  programs.nix-index = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = pkgs.nix-index.name;
      paths = [
        (pkgs.writeTextDir "etc/profile.d/command-not-found.sh" ''
          #!/bin/sh

          # for bash 4
          # this will be called when a command is entered
          # but not found in the user’s path + environment
          command_not_found_handle () {

              # TODO: use "command not found" gettext translations

              # taken from http://www.linuxjournal.com/content/bash-command-not-found
              # - do not run when inside Midnight Commander or within a Pipe
              if [ -n "''${MC_SID-}" ] || ! [ -t 1 ]; then
                  >&2 echo "$1: command not found"
                  return 127
              fi

              toplevel=nixpkgs # nixpkgs should always be available even in NixOS
              cmd=$1
              attrs=$(${pkgs.nix-index}/bin/nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$cmd")
              len=$(echo -n "$attrs" | grep -c "^")

              case $len in
                  0)
                      >&2 echo "$cmd: command not found"
                      ;;
                  1)
                      >&2 cat <<EOF
          $cmd may be found in the following packages:
            $attrs
          EOF
                      printf "Would you like to run this now [yn]? "
                      read -r yn
                      if [ "$yn" = "y" ]; then
                          nix shell "$toplevel#$attrs" -c "$@"
                      fi
                      ;;
                  *)
                      >&2 cat <<EOF
          $cmd may be found in the following packages:
          EOF
                      while read attr; do
                          >&2 echo "  $attr"
                      done <<< "$attrs"
                      ;;
              esac

              return 127 # command not found should always exit with 127
          }

          # for zsh...
          # we just pass it to the bash handler above
          # apparently they work identically
          command_not_found_handler () {
              command_not_found_handle "$@"
              return $?
          }
        '')
        pkgs.nix-index
      ];
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";
}
