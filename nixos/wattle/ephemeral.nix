{ config, lib, ... }:
{
  # Ephemeral root
  fileSystems."/" = {
    device = "rpool/ephemeral/nixos";
    fsType = "zfs";
  };
  boot.initrd.postDeviceCommands =
    assert config.boot.resumeDevice != "";
    lib.mkAfter ''
      if [ "swsuspend" != "$(udevadm info -q property --property=ID_FS_TYPE --value "${config.boot.resumeDevice}")" ]; then
        echo "rolling back rpool/ephemeral/nixos@blank..."
        zfs rollback rpool/ephemeral/nixos@blank
      fi
    '';

  # Selective persistence
  fileSystems."/persist" = {
    device = "rpool/ds1/ROOT/nixos";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/var/tmp" = {
    device = "rpool/var";
    fsType = "zfs";
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

  # Avoid getting the sudo lecture on every boot
  security.sudo.extraConfig = "Defaults lecture=never";

  # Persist machine-id
  # TODO this causes this error during boot, which corresponds to ": >> /etc/machine-id":
  # stage-2-init: /nix/store/a5ikk2k4js252mc3pm3lh1kds4d2lb4l-nixos-system-nixos-23.05.20221216.757b822/init: line 130: /etc/machine-id: Read-only file system
  environment.etc.machine-id.text = "aa3464d9f5e84295a56905d47133b587\n";
}
