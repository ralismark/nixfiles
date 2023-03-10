# File originally generated by 'nixos-generate-config'
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "rpool/ephemeral/nixos";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    {
      device = "rpool/ds1/ROOT/nixos";
      fsType = "zfs";
      neededForBoot = true;
    };

  fileSystems."/mnt/efi" =
    {
      device = "/dev/disk/by-uuid/AE7E-AF45";
      fsType = "vfat";
    };

  fileSystems."/mnt/manjaro" =
    {
      device = "rpool/ds1/ROOT/manjaro";
      fsType = "zfs";
      neededForBoot = true;
    };

  fileSystems."/boot" =
    {
      device = "/mnt/efi/EFI/nixos";
      fsType = "none";
      options = [ "bind" ];
    };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp58s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
