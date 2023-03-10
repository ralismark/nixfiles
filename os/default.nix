# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, inputs, repo-root, ... }:
{
  imports =
    [
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./ephemeral.nix
      ./pin.nix
    ];

  # Autumn Compass ============================================================

  networking.hosts."54.252.155.255" = ["oldgalapagos.autumncompass.com"];
  networking.hosts."52.62.77.124"   = ["devpi.autumncompass.com" "upsource.autumncompass.com" "jira.autumncompass.com" "confluence.autumncompass.com" "svn.autumncompass.com"];
  networking.hosts."52.63.56.149"   = ["relay.srv.autumncompass.com" "sg.gatherer.autumncompass.com" "krs.gatherer.autumncompass.com" "krb.gatherer.autumncompass.com" "cn.gatherer.autumncompass.com" "au.gatherer.autumncompass.com" "prometheus.autumncompass.com"];
  networking.hosts."3.137.64.81"    = ["galapagos.autumncompass.com" "gaze.autumncompass.com"];
  networking.hosts."13.55.249.70"   = ["dev2.autumncompass.com"];
  networking.hosts."52.62.178.137"  = ["dev4.autumncompass.com"];

  # General Configuration =====================================================

  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_AU.UTF-8";

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    wlr.settings.screencast = {
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
  };

  programs.steam.enable = true;

  # QMK development
  services.udev.packages = [ pkgs.qmk-udev-rules ];

  # Networking ================================================================

  networking.hostName = "wattle";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false; # personal system; don't need a firewall

  # Graphical =================================================================

  hardware.opengl.enable = true;

  console = {
    font = ""; # hope this is okay
    colors = [
      # Solarised w/ corrected bright colours
      "002b36"
      "dc322f"
      "859900"
      "b58900"
      "268bd2"
      "d33682"
      "2aa198"
      "eee8d5"
      "586e75"
      "e35d5b"
      "b1cc00"
      "e8b000"
      "4ca2df"
      "dc609c"
      "35c9be"
      "fdf6e3"
    ];
  };

  fonts = {
    enableDefaultFonts = false; # enable base font package set
    fonts = with pkgs; [
      cascadia-code
      font-droid
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji-blob-bin
    ];

    fontconfig.allowType1 = true;
    fontDir.decompressFonts = true;
    fontconfig.defaultFonts = {
      serif = [ "Droid Serif" "Noto Serif" ];
      sansSerif = [ "Droid Sans" "Noto Sans" ];
      monospace = [ "Cascadia Code PL" "Noto Sans Mono" ];
      emoji = [ "Blobmoji" ];
    };
  };

  # make gtk work?
  programs.dconf.enable = true; # Required for some user config

  # TODO are these necessary?
  environment.systemPackages = with pkgs; [
    gnome.adwaita-icon-theme
    hicolor-icon-theme

    shared-mime-info
    sshfs
  ];
  environment.pathsToLink = [
    "/share/icons"
    "/share/mime"
  ];

  # Audio =====================================================================

  sound.enable = false; # <https://nixos.wiki/wiki/PipeWire>: "Remove sound.enable or turn it off if you had it set previously, it seems to cause conflicts with pipewire"
  security.rtkit.enable = true; # realtime support; recommended for pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true; # alsa compat
    alsa.support32Bit = true;
    pulse.enable = true; # pulseaudio compat
  };

  # Misc ======================================================================

  environment.etc."issue".source = ../assets/etc-issue;

  services.udisks2.enable = true;

  virtualisation.docker.enable = true;

  # Boot & System Base ========================================================

  boot.resumeDevice = "/dev/disk/by-partuuid/41c69eeb-9417-4331-ad28-05c4dda54bdf";
  swapDevices = [
    {
      device = config.boot.resumeDevice;
    }
  ];

  # Use the systemd-boot EFI boot loader.
  # TODO replace with rEFInd
  boot.loader.efi.efiSysMountPoint = "/mnt/efi";
  boot.loader.systemd-boot.enable = true;

  # ZFS
  networking.hostId = "8425e349";
  boot.kernelPackages =
    let
      k = pkgs.linuxPackages;
      k_zfs = config.boot.zfs.package.latestCompatibleLinuxPackages;
    in
    assert (builtins.compareVersions k.kernel.version k_zfs.kernel.version) <= 0;
    k;
  boot.tmpOnTmpfs = false; # root is ephemeral so no tmpfs
  boot.zfs.forceImportRoot = false;
  boot.zfs.allowHibernation = true; # TODO switch on true when we know things are safe
  boot.supportedFilesystems = [
    "zfs"
    "ntfs"
  ];
  services.zfs.autoScrub.enable = true;

  systemd.services."zfs-snapshot-boot" = {
    description = "zfs snapshot on boot";
    unitConfig.DefaultDependencies = false;
    serviceConfig.Type = "oneshot";
    script = let
      dataset = "rpool/ds1/ROOT/nixos";
    in ''
      ${config.boot.zfs.package}/bin/zfs snapshot -r ${dataset}@$(date +'%Y-%m-%dT%H-%M-%S')-boot
    '';
    wantedBy = [ "multi-user.target" ];
  };

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
      "networkmanager" # allow networkmanager config without sudo
      "docker" # docker access permissions
    ];
  };

  # Nix =======================================================================

  nix = {
    package = pkgs.nixUnstable;
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
      dates = "weekly";
      randomizedDelaySec = "45min";
      persistent = true;
    };
  };
  system.copySystemConfiguration = false; # This doesn't work with flakes

  # use persistent flake for nixos-rebuild
  environment.etc."nixos/flake.nix".source = "${repo-root}/flake.nix";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
