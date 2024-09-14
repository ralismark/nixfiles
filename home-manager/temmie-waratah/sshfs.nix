{ config, lib, ... }:
with lib;
let
  mounts = {
    "cse" = "cse:";
    "aos-2" = "aos-2:";
  };

  mountBase = "${config.home.homeDirectory}/.local/mount/";

  # -----------------------------------------------------------------------------

  # Escape a path according to the systemd rules, e.g. /dev/xyzzy
  # becomes dev-xyzzy.
  # from <nixpkgs/nixos/lib/utils.nix>
  escapeSystemdPath = s:
    replaceStrings [ "/" "-" " " ] [ "-" "\\x2d" "\\x20" ]
      (removePrefix "/" s);
in
{
  programs.zsh.dirHashes = mapAttrs'
    (mountName: target: {
      name = mountName;
      value = "${mountBase}${mountName}";
    })
    mounts;

  systemd.user.mounts =
    let
      makeMount = mountName: target:
        let mountpoint = "${mountBase}${mountName}";
        in {
          name = escapeSystemdPath mountpoint;
          value = {
            Unit = {
              Description = "sshfs mount ${target} to ${mountpoint}";
            };

            Mount = {
              What = target;
              Where = mountpoint;
              Type = "fuse.sshfs";
              Options = builtins.concatStringsSep "," [
                "idmap=user"
                "x-systemd.automount"
                "_netdev"
                # sshfs opts
                "reconnect"
                #"delay_connect"
                # ssh opts
                "ControlPath=none"
                "ServerAliveInterval=5"
              ];
              LazyUnmount = true;
            };

            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        };
    in
    mapAttrs' makeMount mounts;
}
