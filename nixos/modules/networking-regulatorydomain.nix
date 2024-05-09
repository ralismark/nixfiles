{ config, lib, pkgs, ... }:
let
  # TODO validate format
  cfg = config.networking.regulatoryDomain;
in {
  options.networking.regulatoryDomain = lib.mkOption {
    type = with lib.types; nullOr str;
    default = null;
    description = ''
      If not null, automatically set the wireless regulatory domain to this.
    '';
  };

  config = lib.mkIf (cfg != null) {
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="module", DEVPATH=="/module/cfg80211", RUN+="${pkgs.iw}/bin/iw reg set ${cfg}"
    '';
  };
}
