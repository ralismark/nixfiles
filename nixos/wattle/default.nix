# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config
, pkgs
, ... }:
{
  imports =
    [
      ../../assets/pin-nixpkgs.nix
      ../modules/services-pipewire-filters.nix
      ../modules/networking-regulatorydomain.nix

      ./hardware-configuration.nix # Include the results of the hardware scan.
    ];

  # General Configuration =====================================================

  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_AU.UTF-8";

  services.udev.packages = [
    pkgs.qmk-udev-rules # QMK development
  ];

  environment.etc."issue".source = ../../assets/etc-issue;

  environment.systemPackages = with pkgs; [
    sshfs

    # fix "Unable to load nw-resize from the cursor theme" <https://github.com/NixOS/nixpkgs/issues/207339>
    gnome.adwaita-icon-theme
  ];

  environment.pathsToLink = [ "/share/zsh" ];

  boot.kernel.sysctl."fs.inotify.max_user_instances" = 512; # from default of 128, since lua-language-server uses hundreds...

  # Services & Programs =======================================================

  programs.steam.enable = true;

  programs.adb.enable = true;
  users.groups.adb.members = [ "temmie" ];

  services.udisks2.enable = true;

  virtualisation.docker.enable = true;
  users.groups.docker.members = [ "temmie" ];

  # make programs built for non-Nix (and assuming LSB) work
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # core: <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/requirements.html>
      libxcrypt-legacy # libcrypt.so.1
      glibc # libdl.so.2 libpthread.so.0 librt.so.1 libutil.so.1
      libgcc.lib # libgcc_s.so.1 libstdc++.so.6
      ncurses5 # libncurses.so.5 libncursesw.so.5
      nspr # libnspr4.so
      nss # libnss3.so libssl3.so
      linux-pam # libpam.so.0
      zlib # libz.so.1

      # core (x86-64): <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Core-AMD64/LSB-Core-AMD64/requirements.html#TBL-ARCHLSB-STDLIB>
      # glibc # libc.so.6 libm.so.6

      # desktop: <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/requirements.html#TBL-DESKTOPLIB>
      libglvnd # libGL.so.1
      libGLU # libGLU.so.1
      xorg.libICE # libICE.so.6
      xorg.libSM # libSM.so.6
      xorg.libX11 # libX11.so.6
      xorg.libXext # libXext.so.6
      xorg.libXft # libXft.so.2
      xorg.libXi # libXi.so.6
      xorg.libXrender # libXrender.so.1
      xorg.libXt # libXt.so.6
      xorg.libXtst # libXtst.so.6
      alsa-lib # libasound.so.2
      at-spi2-atk # libatk-1.0.so.0
      cairo # libcairo.so.2 libcairo-gobject.so.2 libcairo-script-interpreter.so.2
      fontconfig # libfontconfig.so.1
      freetype # libfreetype.so.6
      gtk2 # libgdk-x11-2.0.so.0 libgtk-x11-2.0.so.0
      gdk-pixbuf # libgdk_pixbuf-2.0.so.0
      gdk-pixbuf-xlib # libgdk_pixbuf_xlib-2.0.so.0
      glib # libgio-2.0.so.0 libglib-2.0.so.0 libgmodule-2.0.so.0 libgobject-2.0.so.0 libgthread-2.0.so.0
      libjpeg # libjpeg.so.62
      pango # libpango-1.0.so.0 libpangocairo-1.0.so.0 libpangoft2-1.0.so.0 libpangoxft-1.0.so.0
      libpng12 # libpng12.so.0
      libtiff # libtiff.so.6 (instead of .5)
      xorg.libxcb # libxcb.so.1

      # imaging: <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/requirements.html#TBL-IMAGINGLIB>
      cups.lib # libcups.so.2 libcupsimage.so.2
      sane-backends # libsane.so.1

      # language: <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/requirements.html#TBL-LANGUAGESLIB>
      libxml2
      libxslt
    ];
  };

  # Avoid getting the sudo lecture on every boot
  security.sudo.extraConfig = "Defaults lecture=never";

  # Input =====================================================================

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-chinese-addons ];
  };

  # Networking ================================================================

  networking.regulatoryDomain = "AU"; # we're only in AU for now...
  networking.hostName = "wattle";
  networking.networkmanager = {
    enable = true;
    wifi.scanRandMacAddress = false;
    wifi.macAddress = "permanent";
  };
  users.groups.networkmanager.members = [ "temmie" ];
  networking.firewall.enable = false; # personal system; don't need a firewall
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0; # no privileged ports

  services.cloudflared = {
    enable = true;
    tunnels.wattle = {
      credentialsFile = "/persist/secrets/services.cloudflared.tunnels.wattle.credentialsFile.json";
      default = "http://localhost:80";
    };
  };

  # Peripherals ===============================================================

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Graphical =================================================================

  hardware.opengl.enable = true;

  console = {
    font = ""; # hope this is okay
    colors = [
      # Solarised w/ corrected bright colours
      "002b36" # base03
      "dc322f"
      "859900"
      "b58900"
      "268bd2"
      "d33682"
      "2aa198"
      "eee8d5" # base2
      "586e75" # base01
      "e35d5b"
      "b1cc00"
      "e8b000"
      "4ca2df"
      "dc609c"
      "35c9be"
      "fdf6e3" # base3
    ];
    keyMap = pkgs.runCommand "personal.map" {} ''
      ${pkgs.gzip}/bin/gzip --decompress --stdout ${pkgs.kbd}/share/keymaps/i386/qwerty/us.map.gz > $out
      echo "keycode 58 = Escape" >> $out
    '';
  };

  fonts = {
    enableDefaultPackages = false; # enable base font package set
    packages = with pkgs; [
      cascadia-code
      font-droid
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji-blob-bin

      google-fonts
    ];

    fontconfig.allowType1 = true;
    fontDir.decompressFonts = true;
    fontconfig.defaultFonts = {
      # TODO i've put blobmoji near the top to prioritise it over noto; is this necessary?
      # TODO find droid fallback full fonts
      serif = [ "Droid Serif" "emoji" "Noto Serif CJK SC" "Noto Serif" ];
      sansSerif = [ "Droid Sans" "emoji" "Noto Sans CJK SC" "Noto Sans" ];
      monospace = [ "Cascadia Code PL" "emoji" "Noto Sans CJK SC" "Noto Sans Mono" ];
      emoji = [ "Blobmoji" ];
    };
  };

  # make gtk work?
  programs.dconf.enable = true; # Required for some user config

  # Audio =====================================================================

  sound.enable = false; # <https://nixos.wiki/wiki/PipeWire>: "Remove sound.enable or turn it off if you had it set previously, it seems to cause conflicts with pipewire"
  security.rtkit.enable = true; # realtime support; recommended for pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true; # alsa compat
    alsa.support32Bit = true;
    pulse.enable = true; # pulseaudio compat

    deepfilter.enable = true;
  };

  # Boot & Filesystem =========================================================

  # Use the systemd-boot EFI boot loader.
  # TODO replace with rEFInd
  boot.loader.systemd-boot.enable = true;

  # ZFS
  boot.kernelPackages =
    let
      k = pkgs.linuxPackages;
      k_zfs = config.boot.zfs.package.latestCompatibleLinuxPackages;
    in
    assert (builtins.compareVersions k.kernel.version k_zfs.kernel.version) <= 0;
    k;
  boot.tmp.useTmpfs = false; # root is ephemeral so no tmpfs
  boot.zfs.forceImportRoot = false;
  boot.zfs.allowHibernation = true; # TODO switch on true when we know things are safe
  boot.supportedFilesystems = [
    "zfs"
    "ntfs"
  ];
  services.zfs.autoScrub.enable = true;

  systemd.services."zfs-snapshot-boot" = {
    description = "zfs snapshot on boot";
    script = let
      dataset = "rpool/ds1/ROOT/nixos";
    in ''
      ${config.boot.zfs.package}/bin/zfs snapshot -r ${dataset}@$(date +'%Y-%m-%dT%H-%M-%S')-boot
    '';
    wantedBy = [ "multi-user.target" ];

    # run only on startup:
    restartIfChanged = false;
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = "yes"; # make nixos see it as active and so restart
  };

  services.gvfs.enable = true;

  # Users =====================================================================

  users.mutableUsers = false; # generate users purely from configuration
  users.users.root = {
    initialHashedPassword = "$6$m9rBWlrK.LpIrWvt$GKV.usVCCp/Ye65Llh4OjFcp0r74MOJPKO4DPVl9D5N5mJPt71gN1yieQOHHiLoVlqMXdOakaJFz1CspvnqvG.";
  };
  users.users.temmie = {
    uid = 1000;
    isNormalUser = true;
    shell = "/home/temmie/.nix-profile/bin/x-default-shell";
    initialHashedPassword = "$6$duE2AEUJWJRR7mHF$fmn9Zo7RVnRJDkyhfE/TqMzMaRLCAK6mDZJ2DyRO6xt0ycuf.TZ0G57QJDFKBHour2Z2P2diHrLKRBNJDW2HT0";
    extraGroups = [
      "wheel" # allow sudo
    ];
  };

  # Nix =======================================================================

  programs.ssh =  {
    extraConfig = ''
      Host nixbld-julia
        User temmie
        Hostname 152.67.106.24
        Port 6666
        IdentityFile /persist/secrets/root_ed25519
    '';
    knownHostsFiles = [
      (pkgs.writeText "nixbld-julia.known_hosts" ''
        [152.67.106.24]:6666 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBip6fJ2pc0fTEEEnKu2daqsRm6bshloamPiFR8Lh7D8
        [152.67.106.24]:6666 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1iHepGoYStcxTMmqyawKDrdO/iMvxDpj7U5PeamDoxI482hst/d/g6YN6ntGxxJ074/0FbhAVvNF/oNX1n5b7QBSAtj0XTsfsYtXUcw0pXNKWeClgXDS7EcnUnA2J5Xcx3m+CXtSpR3DX2qZ7WEU7GSgXqvaBh2k+zm47drk2cr+q2HxYhUMd3MJwKqCZX4EAgd7xvdiCcotr+/fVs0IDsJO3QkpxRv8OrOhVWvBi57+eOrad8x51xD5PVMaDNT/HP916b8kVJnpgRFzZVd4HsO9yFNwpbvE9115YNXxcmVTiJG1/zec3mqL/cQkIwGN7Z50maUqUWgYxieTHsC9Lbo6+fhuwB4I9vK2P/McilX0l4ayVUS7QLX2CQsjU6ViPVq1zJvIW40ecLcCAl5MO0ryFBe+yY/LaQUKEgfa+5+AJqV79ds9msfHJro2RM1jLoMajXh2wmYhCtctMX+ea8wZ7MNN2fEHyrbCFFSz9K5JrT5eQVrsoUijMdSjPUsaMNPUOcC4Qr2/SW1KJmy9DliDtztf7pkENxU0ymVYbohnL/Y+kR81IzqB+DAeTT/GMAIgruPNT0yb5OI7DIGhAWyeAxJgPuPrqejAGQCc+L/wAkH5KIUmVfGcbBlg+rrbosgGIK+5iK0ZtWT8VvmWxhXmhfi/1YJPkxYRZ8ee9rw==
      '')
    ];
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "temmie" ];
      builders-use-substitutes = true;
      sandbox = "relaxed"; # sorry.... i just need to make things work
    };

    distributedBuilds = true;
    buildMachines = [
      {
        protocol = "ssh-ng";
        hostName = "nixbld-julia";
        system = "x86_64-linux";
      }
    ];

    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "weekly";
      randomizedDelaySec = "45min";
      persistent = true;
    };
  };
  system.copySystemConfiguration = false; # This doesn't work with flakes

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
