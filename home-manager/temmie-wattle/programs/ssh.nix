{ config, lib, pkgs, ... }:
{
  disabledModules = [ "services/ssh-agent.nix" ];

  programs.ssh = {
    enable = true;
    includes = [ "config2" ];

    # options to apply to all hosts
    compression = true;

    controlMaster = "auto";
    controlPath = "\${XDG_RUNTIME_DIR}/sshmux-%r@%h:%p-%l";
    controlPersist = "60";
  };

  # ssh agent -----------------------------------------------------------------

  programs.ssh.extraConfig = ''
    IdentityAgent ''${XDG_RUNTIME_DIR}/ssh-agent
  '';

  # systemd.user.sockets.ssh-agent = {
  #   Unit = {
  #     Description = "SSH authentication agent socket";
  #     Documentation = "man:ssh-agent(1)";
  #   };
  #
  #   Socket = {
  #     ListenStream = "%t/ssh-agent";
  #     SocketMode = "0600";
  #     Service = "ssh-agent.service";
  #   };
  #
  #   Install.WantedBy = ["sockets.target"];
  # };

  systemd.user.services.ssh-agent = {
    Unit = {
      Description = "SSH authentication agent";
      Documentation = "man:ssh-agent(1)";
    };

    Service = {
      Environment = [ "SSH_AUTH_SOCK=%t/ssh-agent" ];
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent";
      ExecStartPost = "${pkgs.openssh}/bin/ssh-add";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
