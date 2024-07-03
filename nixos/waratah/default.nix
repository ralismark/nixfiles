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

  networking.hostName = "waratah";
  networking.hostId = "23a31df2"; # i think this is important for zfs?
  environment.etc.machine-id.text = "cd7249bdbacd8a07e93669c0884d1d9e\n";

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
    lib.mkAfter ''
      echo "rolling back tank/ephemeral/rootfs@blank..."
      zfs rollback tank/ephemeral/rootfs@blank
    '';

  # selective persist
  fileSystems."/persist" = {
    device = "tank/waratah/bootstrap_persist";
    fsType = "zfs";
    neededForBoot = true;
  };

  environment.persistence."/persist" = {
    hideMounts = true; # ux only -- make them not show up in gvfs
    directories = [
      "/nix"
    ];
    files = [
    ];
  };

  # Users =====================================================================

  users.mutableUsers = false; # generate users purely from configuration
  users.users.root = {
    initialHashedPassword = "$6$m9rBWlrK.LpIrWvt$GKV.usVCCp/Ye65Llh4OjFcp0r74MOJPKO4DPVl9D5N5mJPt71gN1yieQOHHiLoVlqMXdOakaJFz1CspvnqvG.";
  };

  # Networking ================================================================

  networking.useDHCP = lib.mkDefault true;

  # Wifi
  networking.networkmanager = {
    enable = true;
    wifi.scanRandMacAddress = false;
    wifi.macAddress = "permanent";
  };

  # Hardware ==================================================================

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Nix =======================================================================

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
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
