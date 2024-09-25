{ lib, pkgs, config, ... }:
with lib;
let
  hasSystemd = config.systemd.user.enable;
in
{
  home.packages = with pkgs; [
    go
    (
      if hasSystemd
      then
        (pkgs.writeScriptBin "gopls" ''
          #!/bin/sh
          exec ${pkgs.systemd}/bin/systemd-run --user --scope --slice=background-gopls.slice --nice=19 ${pkgs.gopls}/bin/gopls "$@"
        '')
      else
        pkgs.gopls
    )
  ];

  systemd.user.slices.background-gopls = lib.mkIf hasSystemd {
    Unit.Description = "Go Language Server";

    Slice = {
      # Make sure it can't take up too much of main memory
      MemoryHigh = "20%";
      MemoryMax = "30%";
      MemorySwapMax = "infinity";
    };
  };
}
