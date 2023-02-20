{ config
, inputs
, lib
, pkgs
, repo-root
, ...
}:
with config;
{
  imports = [
    ./desktop-environment

    ./programs/git.nix
    ./programs/tmux.nix
    ./programs/zsh
    ./toolchains/rust.nix

    ./pin.nix
  ];

  home.packages = [
    (
      let
        links = {
          vim = "${home.homeDirectory}/src/github.com/ralismark/vimfiles/result/bin/vim";
          vim-manpager = "${home.homeDirectory}/src/github.com/ralismark/vimfiles/result/bin/vim-manpager";
          "," = "${home.homeDirectory}/src/github.com/ralismark/micro/nixpkgs-run";
          ",," = "${home.homeDirectory}/src/github.com/ralismark/micro/nixpkgs-shell";
          ",?" = "${home.homeDirectory}/src/github.com/ralismark/micro/nixpkgs-where";
        };
      in
      pkgs.runCommandLocal "pathlinks" { } ''
        mkdir -p $out/bin
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: path: "ln -s ${lib.escapeShellArg path} $out/bin/${lib.escapeShellArg name}") links)}
      ''
    )
    (
      pkgs.python3.withPackages (ps: with ps; [
        ipython
      ])
    )
  ] ++ (
    let
      allLines = lib.splitString "\n" (builtins.readFile ./installed-packages.txt);
      lines = lib.filter (x: x != "") allLines;
      getDrv = i: lib.foldl (x: y: x.${y}) pkgs (lib.splitString "." i);
    in
    map getDrv lines
  );

  # Environment ===============================================================

  home.sessionVariables =
    let
      userBin = "${home.homeDirectory}/.nix-profile/bin";
    in
    {
      EDITOR = "${userBin}/vim";
      VISUAL = "${userBin}/vim";
      MANPAGER = "${userBin}/vim-manpager";
      BROWSER = "${userBin}/firefox";
    };

  # HACK until we have better sessionPath handling
  home.sessionVariablesExtra = ''
    export PATH="$HOME/.local/bin''${PATH:+:}$PATH"
  '';

  # import all session vars into systemd
  systemd.user.sessionVariables =
    (builtins.removeAttrs home.sessionVariables [ ])
    // {
      # TODO this isn't that great -- based on /nix/store/wqklqfzjd407ah21abj5786ljp4ljl35-set-environment
      PATH = "$HOME/.local/bin:/run/wrappers/bin:$PATH:${lib.concatStringsSep ":" home.sessionPath}:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
    };

  # Graphical =================================================================

  gtk = {
    enable = true;

    font = {
      name = "Droid Sans Regular";
      size = 13;
    };

    iconTheme = {
      package = pkgs.numix-reborn-icon-themes;
      name = "Numix-Reborn";
    };
    theme = {
      package = pkgs.adapta-maia-theme;
      name = "Adapta-Nokto-Eta-Maia";
    };

    gtk3.bookmarks = [
      "file:///tmp tmp"
    ];
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  # fonts.fontconfig.enable = true; # "enable fontconfig", not sure what it entails...

  # Auth Agent
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "Gnome PolicyKit authentication agent";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Programs ==================================================================

  programs.less = {
    enable = true;
    # disable .lesshst
    keys = ''
      #env
      LESSHISTFILE=/dev/null
    '';
  };

  programs.bash.enable = true;
  programs.bash.bashrcExtra = ''
    . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
  '';
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = false;

  # Misc ======================================================================

  services.udiskie = {
    enable = true;
  };
  systemd.user.services.udiskie = lib.mkForce {
    # The default unit has dependencies on tray.target and stuff and is kinda shit
    Unit = {
      Description = "udiskie mount daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service.ExecStart = "${pkgs.udiskie}/bin/udiskie --appindicator";
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # fortunes
  home.file.".local/fortunes".source = ./fortunes;
  home.file.".local/fortunes.dat".source = pkgs.runCommand "fortunes.dat" { } ''
    ${pkgs.fortune}/bin/strfile ${./fortunes} $out
  '';

  # Nix =======================================================================

  # nix-index
  home.file.".cache/nix-index/files".source = inputs.nix-index-database.legacyPackages.${nixpkgs.system}.database;
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
              attrs=$(/nix/store/76hrpdp0am22l6fjkc20wikbqaf9zblw-nix-index-0.1.4/bin/nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$cmd")
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
                      read -r -n1 -p "Would you like to run this now [yn]?" yn
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
              command_not_found_handle $@
              return $?
          }
        '')
        pkgs.nix-index
      ];
    };
  };

  programs.home-manager.enable = true;
  xdg.configFile."nixpkgs/flake.nix".source = config.lib.file.mkOutOfStoreSymlink "${repo-root}/flake.nix";

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
