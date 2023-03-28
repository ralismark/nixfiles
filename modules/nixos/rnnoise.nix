{ config
, lib
, pkgs
, ... }:
with lib;
let
  pwcfg = config.services.pipewire;
  cfg = pwcfg.rnnoise;

  # from <https://github.com/werman/noise-suppression-for-voice/blob/master/README.md>
  rnnoiseConf = (generators.toJSON {} {
    "context.modules" = [ {
      name = "libpipewire-module-filter-chain";
      args = {
        "node.description" = "Noise Cancelling source";
        "media.name" = "Noise Cancelling source";
        "filter.graph".nodes = [ {
          type = "ladspa";
          name = "rnnoise";
          plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
          label = "noise_suppressor_mono";
          control = {
            "VAD Threshold (%)" = 50.0;
            "VAD Grace Period (ms)" = 200;
            "Retroactive VAD Grace (ms)" = 0;
          };
        } ];
        "capture.props" = {
          "node.name" = "capture.rnnoise_source";
          "node.passive" = true;
          "audio.rate" = 48000;
        };
        "playback.props" = {
          "node.name" = "rnnoise_soure";
          "media.class" = "Audio/Source";
          "audio.rate" = 48000;
        };
      };
    } ];
  });

  unit = {
    description = "RNNoise plugin for pipewire";

    wantedBy = [ "pipewire.service" ];
    bindsTo = [ "pipewire.service" ];
    after = [ "pipewire.service" ];

    script = ''
      ${pwcfg.package}/bin/pipewire -c ${pkgs.writeText "rnnoise-filter-chain.conf" rnnoiseConf}
    '';
  };
in
{
  options.services.pipewire.rnnoise = {
    enable = mkEnableOption "rnnoise plugin for pipewire";
  };

  config = mkIf cfg.enable {
    systemd.services.pipewire-rnnoise = unit // {
      enable = pwcfg.systemWide;
    };

    systemd.user.services.pipewire-rnnoise = unit // {
      enable = !pwcfg.systemWide;
    };
  };
}
