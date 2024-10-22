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

    ../shared
  ];

  # console.font = "LatGrkCyr-12x22";

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

  boot.resumeDevice = "/dev/disk/by-partuuid/9066e811-c45b-4c8f-bebc-f6da52974b63";
  swapDevices = [
    {
      device = config.boot.resumeDevice;
    }
  ];

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
  boot.initrd.postResumeCommands =
    assert config.fileSystems."/".fsType == "zfs";
    # force this after the zfs pool import
    lib.mkAfter ''
      echo "rolling back ${config.fileSystems."/".device}@blank..."
      zfs rollback ${config.fileSystems."/".device}@blank
    '';
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
      "/var/lib/fprint"
      "/var/lib/nixos" # nixos uid/gid mappings
    ];
    files = [
    ];
  };

  # Services ==================================================================

  services.zfs.autoScrub.enable = true;

  systemd.services."zfs-snapshot-boot" = {
    description = "zfs snapshot on boot";
    script = let
      dataset = "tank/waratah/nixos_persist";
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

  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
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

  # Hardware ==================================================================

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  services.fwupd.enable = true;

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

  # Wakeup
  systemd.tmpfiles.rules = [
    # disable wakeup from keyboard
    "w /sys/devices/pci0000:00/0000:00:02.2/power/wakeup - - - - disabled"
    # disable wakeup from USB devices
    "w /sys/devices/pci0000:00/0000:c1:00.3/power/wakeup - - - - disabled"
    "w /sys/devices/pci0000:00/0000:c1:00.4/power/wakeup - - - - disabled"
    "w /sys/devices/pci0000:00/0000:c3:00.0/power/wakeup - - - - disabled"
    "w /sys/devices/pci0000:00/0000:c3:00.5/power/wakeup - - - - disabled"
    "w /sys/devices/pci0000:00/0000:c3:00.3/power/wakeup - - - - disabled"
    "w /sys/devices/pci0000:00/0000:c3:00.6/power/wakeup - - - - disabled"
    "w /sys/devices/pci0000:00/0000:c3:00.4/power/wakeup - - - - disabled"
  ];

  services.logind = {
    lidSwitch = "suspend";
    lidSwitchDocked = "suspend";
    lidSwitchExternalPower = "suspend";
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
      trusted-users = [ "@wheel" ];
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
