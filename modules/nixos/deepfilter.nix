{ config
, lib
, pkgs
, ... }:
with lib;
let
  pwcfg = config.services.pipewire;
  cfg = pwcfg.deepfilter;

  # based on <https://github.com/Rikorose/DeepFilterNet/blob/main/ladspa/filter-chain-configs/deepfilter-mono-source.conf>
  deepFilterConf = generators.toJSON {} {
    "context.properties" = {
      "log.level" = 0;
    };
    "context.spa-libs" = {
      "audio.convert.*" = "audioconvert/libspa-audioconvert";
      "support.*" = "support/libspa-support";
    };

    "context.modules" = [
      {
        name = "libpipewire-module-rtkit";
        args = {
          #"nice.level"   = -11;
          #"rt.prio"      = 88;
          #"rt.time.soft" = 2000000;
          #"rt.time.hard" = 2000000;
        };
        flags = [ "ifexists" "nofail" ];
      }
      { name = "libpipewire-module-protocol-native"; }
      { name = "libpipewire-module-client-node"; }
      { name = "libpipewire-module-adapter"; }

      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "DeepFilter Noise Canceling Source";
          "media.name" = "DeepFilter Noise Canceling Source";
          "filter.graph".nodes = [ {
            type = "ladspa";
            name = "DeepFilter Mono";
            plugin = "${pkgs.deepfilternet-ladspa}/lib/libdeep_filter_ladspa.so";
            label = "deep_filter_mono";
            control = {
              "Attenuation Limit (dB)" = 100;
            };
          } ];
          "audio.rate" = 48000;
          "capture.props" = {
            "node.passive" = true;
          };
          "playback.props" = {
            "media.class" = "Audio/Source";
          };
        };
      }
    ];
  };

  unit = {
    description = "DeepFilter plugin for pipewire";

    wantedBy = [ "pipewire.service" ];
    bindsTo = [ "pipewire.service" ];
    after = [ "pipewire.service" ];

    path = with pkgs; [pipewire];

    script = ''
      ${pwcfg.package}/bin/pipewire -c ${pkgs.writeText "deepfilter-mono-source.conf" deepFilterConf}
    '';
  };
in
{
  options.services.pipewire.deepfilter = {
    enable = mkEnableOption "deepfilter plugin for pipewire";
  };

  config = mkIf cfg.enable {
    systemd.services.pipewire-deepfilter = unit // {
      enable = pwcfg.systemWide;
    };

    systemd.user.services.pipewire-deepfilter = unit // {
      enable = !pwcfg.systemWide;
    };
  };
}
