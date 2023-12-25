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

      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./ephemeral.nix
    ];

  # General Configuration =====================================================

  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_AU.UTF-8";

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    wlr.enable = true;
    wlr.settings.screencast = {
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
  };

  programs.steam.enable = true;

  services.udev.packages = [
    pkgs.qmk-udev-rules # QMK development
  ];

  programs.adb.enable = true;

  # Misc ======================================================================

  environment.etc."issue".source = ../../assets/etc-issue;

  services.udisks2.enable = true;

  virtualisation.docker.enable = true;

  # Input =====================================================================

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-chinese-addons ];
  };

  # Networking ================================================================

  networking.hostName = "wattle";
  networking.networkmanager.enable = true;
  networking.firewall.enable = false; # personal system; don't need a firewall
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0; # no privileged ports

  services.cloudflared = {
    enable = true;
    tunnels.wattle = {
      credentialsFile = "/persist/secrets/services.cloudflared.tunnels.wattle.credentialsFile.json";
      default = "http://localhost:80";
    };
  };

  services.gvfs.enable = true;

  # Peripherals ===============================================================

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

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

  environment.systemPackages = with pkgs; [
    sshfs

    # fix "Unable to load nw-resize from the cursor theme" <https://github.com/NixOS/nixpkgs/issues/207339>
    gnome.adwaita-icon-theme
  ];

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

  boot.resumeDevice = "/dev/disk/by-partuuid/41c69eeb-9417-4331-ad28-05c4dda54bdf";
  swapDevices = [ {
    device = config.boot.resumeDevice;
  } ];
  systemd.tmpfiles.rules = [
    "w /sys/devices/pci0000:00/0000:00:14.0/power/wakeup - - - - disabled" # USB xHCI controller
  ];
  # services.udev.extraRules = ''
  #   ACTION=="add|change", SUBSYSTEM=="usb", ATTR{power/wakeup}="disabled"
  # '';

  boot.loader.efi.efiSysMountPoint = "/efi";
  fileSystems."/efi" = {
    device = "/dev/disk/by-partuuid/6cce0e24-d05c-469c-bf80-a48ed1fb637a";
    fsType = "vfat";
  };

  # Use the systemd-boot EFI boot loader.
  # TODO replace with rEFInd
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
      "adbusers"
    ];
  };

  # Nix =======================================================================

  nix = {
    package = pkgs.nixUnstable;
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "temmie" ];
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
