{ lib, pkgs, ... }:
with lib;
{
  home.packages = with pkgs; [
    go
    (pkgs.writeScriptBin "gopls" ''
      #!/bin/sh
      exec ${pkgs.systemd}/bin/systemd-run --user --scope --slice=background-gopls.slice --nice=19 ${pkgs.gopls}/bin/gopls "$@"
    '')
  ];

  systemd.user.slices.background-gopls = {
    Unit.Description = "Go Language Server";

    Slice = {
      # Make sure it can't take up too much of main memory
      MemoryHigh = "20%";
      MemoryMax = "30%";
      MemorySwapMax = "infinity";
    };
  };
}
