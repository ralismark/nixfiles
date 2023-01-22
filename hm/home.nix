{ config, pkgs, inputs, ... }:

with config;

let
  inherit (pkgs) lib;
in
{
  imports = [
    ./desktop-environment

    ./programs/git.nix
    ./programs/tmux.nix
  ];

  home.packages = [
    (
      let
        links = {
          vim = "${home.homeDirectory}/src/github.com/ralismark/vimfiles/result/bin/vim";
          vim-manpager = "${home.homeDirectory}/src/github.com/ralismark/vimfiles/result/bin/vim-manpager";
        };
      in
      pkgs.runCommandLocal "pathlinks" { } ''
        mkdir -p $out/bin
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: path: "ln -s ${path} $out/bin/${name}") links)}
      ''
    )
    (
      pkgs.python3.withPackages (ps: with ps; [
        ipython
      ])
    )
  ] ++ (import ./installed-packages.nix { inherit pkgs; });

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
      NIX_PATH = lib.concatStringsSep ":" [
        "nixpkgs=${inputs.nixpkgs}"
      ];
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
      Description = "polkit-gnome-authentication-agent-1";
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

  xdg.configFile."nixpkgs/config.nix".source = ../nixpkgs-config.nix;
  nix.package = pkgs.nixUnstable;
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # nix-index
  home.file.".cache/nix-index/files".source = inputs.nix-index-database.legacyPackages.${nixpkgs.system}.database;
  programs.nix-index = {
    enable = true;
  };

  # Meta ======================================================================

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "temmie";
  home.homeDirectory = "/home/${home.username}";
}
