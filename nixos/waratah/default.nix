{
  config,
  lib,
  pkgs,
  modulesPath,

  ...
}:
{
  imports = [
    ../../assets/pin-nixpkgs.nix
    ../modules/networking-regulatorydomain.nix

    (modulesPath + "/installer/scan/not-detected.nix")

    # ../shared
  ];

  # System Identity ===========================================================

  networking.hostName = "waratah";
  networking.hostId = "23a31df2"; # i think this is important for zfs?
  environment.etc.machine-id.text = "cd7249bdbacd8a07e93669c0884d1d9e\n";

  # Locale ====================================================================

  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_AU.UTF-8";
  networking.regulatoryDomain = "AU";

  # Boot ======================================================================

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true; # install boot entry

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.zfs.forceImportRoot = false;
  boot.zfs.allowHibernation = true;
  boot.supportedFilesystems = [
    "zfs"
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Filesystems ===============================================================

  # EFI partition
  boot.loader.efi.efiSysMountPoint = "/efi";
  fileSystems."/efi" = {
    device = "/dev/disk/by-partuuid/1ece8e18-4b65-4133-b4c2-d2708ac66ac9";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "tank/ephemeral/rootfs";
    fsType = "zfs";
  };
  boot.initrd.postDeviceCommands =
    assert config.fileSystems."/".fsType == "zfs";
    let
      rollbackScript = ''
        echo "rolling back ${config.fileSystems."/".device}@blank..."
        zfs rollback ${config.fileSystems."/".device}@blank
      '';
    in
    lib.mkAfter (if config.boot.resumeDevice == "" then rollbackScript else ''
      if [ "swsuspend" != "$(udevadm info -q property --property=ID_FS_TYPE --value "${config.boot.resumeDevice}")" ]; then
        ${rollbackScript}
      fi
    '');
  boot.tmp.useTmpfs = false; # root is ephemeral so no need for tmpfs /tmp

  # selective persist
  fileSystems."/persist" = {
    device = "tank/waratah/nixos_persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  environment.persistence."/persist" = {
    hideMounts = true; # ux only -- make them not show up in gvfs
    directories = [
      "/nix"
      "/home"
      "/etc/NetworkManager/system-connections" # save network connections
      "/var/lib/systemd/timers" # make timers work across reboots
    ];
    files = [
    ];
  };

  # Services ==================================================================

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

  # Hardware & Networking =====================================================

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Bluetooth
  # hardware.bluetooth.enable = true;

  # Internet
  networking.useDHCP = lib.mkDefault true;

  networking.networkmanager = {
    enable = true;
    wifi.scanRandMacAddress = false;
    wifi.macAddress = "permanent";
  };
  users.groups.networkmanager.members = config.users.groups.users.members;

  # Nix =======================================================================

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "temmie" ];
      builders-use-substitutes = true;
      sandbox = "relaxed"; # sorry.... i just need to make things work
    };

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
