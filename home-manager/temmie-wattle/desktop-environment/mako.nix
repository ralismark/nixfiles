{ config, lib, ... }:
let
  mako-pkg = "${config.services.mako.package}";
in
{
  services.mako = {
    enable = true;

    maxVisible = -1;
    output = "eDP-1";
    width = 400;
    height = 9999; # unbounded?

    font = "sans-serif Regular 15";
    backgroundColor = "#191311";

    format = ''<span font_family="monospace" size="12000">%a</span>\n<b>%s</b>\n%b'';

    extraConfig = ''
      [mode=do-not-disturb]
      invisible=1
    '';
  };

  # See home-manager#3266 <https://github.com/nix-community/home-manager/pull/3266>

  xdg.dataFile."dbus-1/services/fr.emersion.mako.service".text =
    lib.generators.toINI { } {
      "D-BUS Service" = {
        Name = "org.freedesktop.Notifications";
        Exec = "/bin/false";
        SystemdService = "mako.service";
      };
    };

  systemd.user.services.mako = {
    Unit = {
      Description = "Lightweight Wayland notifcation deamon";
      Documentation = "man:mako(1)";
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${mako-pkg}/bin/mako";
      ExecReload = "${mako-pkg}/bin/makoctl reload";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
