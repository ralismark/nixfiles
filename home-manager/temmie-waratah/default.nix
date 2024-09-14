{ config
, inputs
, lib
, pkgs
, ...
}:
with config;
let
  pkgsFile = pkgs.callPackage ../../lib/attrs-file.nix { };

  python-env = pkgs.python3.withPackages
    (ps: pkgsFile {
      keys = ./installed-python3.txt;
      pkgs = ps;
    });
in {
  imports = [
    ../../assets/pin-nixpkgs.nix
    ../modules/home-bin.nix

    ./desktop-environment

    ./programs/git.nix
    ./programs/tmux.nix
    ./programs/zsh
    ./programs/firefox
    ./programs/ipython
    ./programs/jupyter.nix
    ./programs/ssh.nix

    ./toolchains/rust.nix
    ./toolchains/go.nix

    ./sshfs.nix
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
      tunnel-run.source = "${micro}/tunnel-run";
      give.source = "${micro}/give";
      what-is-my-ip.text = ''
        #!/bin/sh
        ${pkgs.dig.dnsutils}/bin/dig +short @1.1.1.1 ch txt whoami.cloudflare +time=3 |
          ${pkgs.coreutils}/bin/tr -d \"
      '';

      xdg-open.text = ''
        #!/bin/sh

        if [ "$#" -ne 1 ]; then
          echo >&2 "Usage: xdg-open { file | url }"
          echo >&2 ""
          echo >&2 "This is a replacement for xdg_util's xdg-open, which is way too complicated."
          exit 127
        fi

        targetFile=$1

        if [ -e "$targetFile" ]; then
          exec 3< "$targetFile"
          ${pkgs.glib}/bin/gdbus call --session \
            --dest org.freedesktop.portal.Desktop \
            --object-path /org/freedesktop/portal/desktop \
            --method org.freedesktop.portal.OpenURI.OpenFile \
            --timeout 5 \
            "" "3" '{}'
        else
          if ! echo "$targetFile" | grep -q '://'; then
            targetFile="https://$targetFile"
          fi

          ${pkgs.glib}/bin/gdbus call --session \
            --dest org.freedesktop.portal.Desktop \
            --object-path /org/freedesktop/portal/desktop \
            --method org.freedesktop.portal.OpenURI.OpenURI \
            --timeout 5 \
            "" "$targetFile" '{}'
        fi
      '';

      "restic.sh".text = ''
        #!/bin/sh
        set -a
        RESTIC_PASSWORD=restic
        RESTIC_COMPRESSION=max
        RESTIC_REPOSITORY=rclone:b2:ralismark-glacier/restic
        RESTIC_CACHE_DIR=/tmp/restic-cache.$USER
        set +a

        exec ${pkgs.restic}/bin/restic \
          -o rclone.program=${pkgs.rclone}/bin/rclone \
          -o rclone.args="serve restic --stdio --transfers 16 --config /persist/secrets/rclone.conf" \
          "$@"
      '';
    };

  home.shellAliases.git = "tunnel-run git";

  home.packages = lib.flatten [
    python-env
    (pkgsFile {
      keys = ./installed-packages.txt;
      pkgs = pkgs;
    })
  ];

  services.jupyter-notebook = {
    enable = true;
    env = python-env;
  };

  xdg.desktopEntries = {
    vim = {
      name = "Vim";
      exec = "vim";
      terminal = true;
      mimeType = [
        "text/plain"
      ];
    };
    dfeet = {
      name = "D-Feet";
      exec = "nix run -f \"<nixpkgs>\" dfeet --";
      icon = pkgs.fetchurl {
        url = "https://wiki.gnome.org/Apps/DFeet?action=AttachFile&do=get&target=d-feet-logo.png";
        hash = "sha256-Bqt/tZdHuGndzV5pj1i6fcbUnzPuaF4n1u/A7yf/qbs=";
      };
    };
    isabelle = {
      name = "Isabelle";
      exec = "nix run -f \"<nixpkgs>\" isabelle -- jedit";
      icon = pkgs.fetchurl {
        url = "https://isabelle.in.tum.de/img/isabelle.png";
        hash = "sha256-PY/xbT94MqYACN0nY/Ci1SXHcQha+h1Dk9JBk7otOyg=";
      };
    };
    musescore = {
      name = "MuseScore";
      exec = "nix run -f \"<nixpkgs>\" musescore --";
      icon = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/musescore/MuseScore/master/share/icons/AppIcon/MS4_AppIcon_64x64.png";
        hash = "sha256-j5aZmJPTR6UeHPVKSpQFSQKGPL83d5Gwwu2SMSyGltk=";
      };
    };
    audacity = {
      name = "Audacity";
      exec = "nix run -f \"<nixpkgs>\" audacity --";
      icon = pkgs.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/e/e2/Audacity_Logo_nofilter.svg";
        hash = "sha256-k7yNcL7rAC8dqVdmrPyQZU0kx6OqkSpAQ6SjIcQNuLE=";
      };
    };
    xournalpp = {
      name = "Xournal++";
      exec = "nix run -f \"<nixpkgs>\" xournalpp --";
      icon = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/xournalpp/xournalpp/c5ddca935d23883288251a970ee1a16c27e02a5f/ui/pixmaps/com.github.xournalpp.xournalpp.svg";
        hash = "sha256-q19BBkVFjs+CxX8Q/4WJJZnRz2cM4ag84P5c5jZV1e8=";
      };
      mimeType = [
        "application/pdf"
        "application/postscript"
        "application/x-ext-pdf"
      ];
    };
    wireshark = {
      name = "wireshark";
      exec = "nix run -f \"<nixpkgs>\" wireshark --";
    };
  };

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
      TZ = ":/etc/localtime";
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
    platformTheme.name = "gtk";
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
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config = {
      global.warn_timeout = "99999h";
    };
  };

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = let
    assoc = app: mimes: lib.genAttrs mimes (_: app);
  in (assoc "org.gnome.Evince.desktop" [
    "application/pdf"
    "application/postscript"
    "application/x-ext-pdf"
  ]) // (assoc "org.nomacs.ImageLounge.desktop" [
    "image/bmp"
    "image/gif"
    "image/jpeg"
    "image/png"
    "image/tiff"
  ]) // (assoc "firefox-devedition.desktop" [
    "application/rdf+xml"
    "application/rss+xml"
    "application/xhtml+xml"
    "application/xhtml_xml"
    "application/xml"
    "text/html"
    "text/xml"
    "x-scheme-handler/about"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/mailto"
    "x-scheme-handler/unknown"
    "x-scheme-handler/webcal"
  ]) // (assoc "org.gnome.FileRoller.desktop" [
    "application/bzip2"
    "application/gzip"
    "application/vnd.android.package-archive"
    "application/vnd.debian.binary-package"
    "application/vnd.ms-cab-compressed"
    "application/x-7z-compressed"
    "application/x-7z-compressed-tar"
    "application/x-ace"
    "application/x-alz"
    "application/x-apple-diskimage"
    "application/x-ar"
    "application/x-archive"
    "application/x-arj"
    "application/x-brotli"
    "application/x-bzip"
    "application/x-bzip-brotli-tar"
    "application/x-bzip-compressed-tar"
    "application/x-bzip1"
    "application/x-bzip1-compressed-tar"
    "application/x-cabinet"
    "application/x-cd-image"
    "application/x-chrome-extension"
    "application/x-compress"
    "application/x-compressed-tar"
    "application/x-cpio"
    "application/x-deb"
    "application/x-ear"
    "application/x-gtar"
    "application/x-gzip"
    "application/x-gzpostscript"
    "application/x-java-archive"
    "application/x-lha"
    "application/x-lhz"
    "application/x-lrzip"
    "application/x-lrzip-compressed-tar"
    "application/x-lz4"
    "application/x-lz4-compressed-tar"
    "application/x-lzip"
    "application/x-lzip-compressed-tar"
    "application/x-lzma"
    "application/x-lzma-compressed-tar"
    "application/x-lzop"
    "application/x-ms-dos-executable"
    "application/x-ms-wim"
    "application/x-rar"
    "application/x-rar-compressed"
    "application/x-rpm"
    "application/x-rzip"
    "application/x-rzip-compressed-tar"
    "application/x-source-rpm"
    "application/x-stuffit"
    "application/x-tar"
    "application/x-tarz"
    "application/x-tzo"
    "application/x-war"
    "application/x-xar"
    "application/x-xz"
    "application/x-xz-compressed-tar"
    "application/x-zip"
    "application/x-zip-compressed"
    "application/x-zoo"
    "application/x-zstd-compressed-tar"
    "application/zip"
    "application/zstd"
  ]);

  xdg.configFile."rclone/rclone.conf".source = config.lib.file.mkOutOfStoreSymlink "/persist/secrets/rclone.conf";

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

  # Nix =======================================================================

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
