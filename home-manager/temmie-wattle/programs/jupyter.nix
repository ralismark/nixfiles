{ config, lib, pkgs, ... }:
let
  cfg = config.services.jupyter-notebook;
in
{
  options.services.jupyter-notebook = {
    enable = lib.mkEnableOption "jupyter notebook server";
    env = lib.mkPackageOption pkgs "jupyter" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.sockets.jupyter-notebook-proxy = {
      Socket.ListenStream = 8888;

      Install.WantedBy = [ "sockets.target" ];
    };

    systemd.user.services.jupyter-notebook-proxy = {
      Unit = {
        Requires = [ "jupyter-notebook.service" "jupyter-notebook-proxy.socket" ];
        After = [ "jupyter-notebook.service" "jupyter-notebook-proxy.socket" ];
      };

      Service = {
        Type = "notify";
        ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd localhost:8889";
      };
    };

    systemd.user.services.jupyter-notebook = {
      Unit = {
        Description = "Jupyter notebook";
      };

      Service = {
        # TODO make service only finish activation when port is connected

        ExecStart = builtins.concatStringsSep " " [
          "${cfg.env}/bin/jupyter"
          "notebook"
          "--no-browser"
          "--MappingKernelManager.cull_idle_timeout=3600"
          "--ServerApp.port=8889"
          "--IdentityProvider.token="
        ];

        WorkingDirectory = "%h";
        Restart = "always";
        RestartSec = 10;
        Nice = 10;
      };
    };
  };
}
