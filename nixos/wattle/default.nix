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
      ../shared
    ];

  # Locale ====================================================================

  networking.hostName = "wattle";

  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_AU.UTF-8";
  networking.regulatoryDomain = "AU";

  # General Configuration =====================================================

  i18n.inputMethod = {
    # enabled = "fcitx5";
    # fcitx5.addons = with pkgs; [ fcitx5-chinese-addons ];
  };

  services.cloudflared = {
    enable = true;
    tunnels.wattle = {
      credentialsFile = "/persist/secrets/services.cloudflared.tunnels.wattle.credentialsFile.json";
      default = "http://localhost:80";
    };
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
  boot.zfs.allowHibernation = true;
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
      "users"
      "wheel" # allow sudo
    ];
  };

  # Hardware-specific =========================================================

  # map capslock to escape
  console.keyMap = pkgs.runCommand "personal.map" {} ''
    ${pkgs.gzip}/bin/gzip --decompress --stdout ${pkgs.kbd}/share/keymaps/i386/qwerty/us.map.gz > $out
    echo "keycode 58 = Escape" >> $out
  '';

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Wifi
  networking.networkmanager = {
    enable = true;
    wifi.scanRandMacAddress = false;
    wifi.macAddress = "permanent";
  };
  users.groups.networkmanager.members = config.users.groups.users.members;

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}
