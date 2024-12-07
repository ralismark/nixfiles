{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../modules/services-pipewire-filters.nix
  ];

  environment.systemPackages = with pkgs; [
    sshfs # for use with systemd

    pkgs.adwaita-icon-theme  # fix "Unable to load nw-resize from the cursor theme" <https://github.com/NixOS/nixpkgs/issues/207339>
  ];

  # Misc Config ===============================================================

  # Include zsh completions from system packages
  environment.pathsToLink = [ "/share/zsh" ];

  boot.kernel.sysctl."fs.inotify.max_user_instances" = 512; # from default of 128, since lua-language-server uses hundreds...

  networking.firewall.enable = false; # personal system; don't need a firewall
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0; # no privileged ports; anyone can bind to any port

  # make programs built for non-Nix (and assuming LSB) work
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # core: <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/requirements.html>
      libxcrypt-legacy # libcrypt.so.1
      glibc # libdl.so.2 libpthread.so.0 librt.so.1 libutil.so.1
      libgcc.lib # libgcc_s.so.1 libstdc++.so.6
      ncurses5 # libncurses.so.5 libncursesw.so.5
      nspr # libnspr4.so
      nss # libnss3.so libssl3.so
      linux-pam # libpam.so.0
      zlib # libz.so.1

      # core (x86-64): <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Core-AMD64/LSB-Core-AMD64/requirements.html#TBL-ARCHLSB-STDLIB>
      # glibc # libc.so.6 libm.so.6

      # desktop: <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/requirements.html#TBL-DESKTOPLIB>
      libglvnd # libGL.so.1
      libGLU # libGLU.so.1
      xorg.libICE # libICE.so.6
      xorg.libSM # libSM.so.6
      xorg.libX11 # libX11.so.6
      xorg.libXext # libXext.so.6
      xorg.libXft # libXft.so.2
      xorg.libXi # libXi.so.6
      xorg.libXrender # libXrender.so.1
      xorg.libXt # libXt.so.6
      xorg.libXtst # libXtst.so.6
      alsa-lib # libasound.so.2
      at-spi2-atk # libatk-1.0.so.0
      cairo # libcairo.so.2 libcairo-gobject.so.2 libcairo-script-interpreter.so.2
      fontconfig # libfontconfig.so.1
      freetype # libfreetype.so.6
      gtk2 # libgdk-x11-2.0.so.0 libgtk-x11-2.0.so.0
      gdk-pixbuf # libgdk_pixbuf-2.0.so.0
      gdk-pixbuf-xlib # libgdk_pixbuf_xlib-2.0.so.0
      glib # libgio-2.0.so.0 libglib-2.0.so.0 libgmodule-2.0.so.0 libgobject-2.0.so.0 libgthread-2.0.so.0
      libjpeg # libjpeg.so.62
      pango # libpango-1.0.so.0 libpangocairo-1.0.so.0 libpangoft2-1.0.so.0 libpangoxft-1.0.so.0
      libpng12 # libpng12.so.0
      libtiff # libtiff.so.6 (instead of .5)
      xorg.libxcb # libxcb.so.1

      # imaging: <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/requirements.html#TBL-IMAGINGLIB>
      cups.lib # libcups.so.2 libcupsimage.so.2
      sane-backends # libsane.so.1

      # language: <https://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/requirements.html#TBL-LANGUAGESLIB>
      libxml2
      libxslt
    ];
  };

  # Disable sudo lecture (which would show on every boot with ephemeral root)
  security.sudo.extraConfig = "Defaults lecture=never";

  # Enable docker
  virtualisation.docker = {
    enable = true;
    daemon.settings.group = lib.mkForce "wheel"; # docker access is equivalent to root
  };

  # Graphical Environment =====================================================

  hardware.graphics.enable = true;

  security.rtkit.enable = true; # realtime support; recommended for pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true; # alsa compat
    alsa.support32Bit = true;
    pulse.enable = true; # pulseaudio compat

    deepfilter.enable = false;
  };

  # enable this here since system-level changes are required for users to run steam
  # programs.steam.enable = true; # uninstalling steam to try and fix my factorio addition :>

  # TODO this is preferably a per-user thing, but the options don't current exist in home-manager
  fonts = {
    enableDefaultPackages = false; # enable base font package set
    packages = with pkgs; [
      cascadia-code
      font-droid
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji-blob-bin

      google-fonts
    ];

    fontconfig.allowType1 = true;
    fontDir.decompressFonts = true;
    fontconfig.defaultFonts = {
      # TODO i've put blobmoji near the top to prioritise it over noto; is this necessary?
      # TODO find droid fallback full fonts
      serif = [ "Droid Serif" "emoji" "Noto Serif CJK SC" "Noto Serif" ];
      sansSerif = [ "Droid Sans" "emoji" "Noto Sans CJK SC" "Noto Sans" ];
      monospace = [ "Cascadia Code PL" "emoji" "Noto Sans CJK SC" "Noto Sans Mono" ];
      emoji = [ "Blobmoji" ];
    };
  };

  # Peripherals ===============================================================

  # for QMK keyboard
  services.udev.packages = [ pkgs.qmk-udev-rules ];

  # for ADB
  programs.adb.enable = true;
  users.groups.adb.members = config.users.groups.users.members;

  # for storage devices
  services.gvfs.enable = true;
  services.udisks2 = {
    enable = true;
    mountOnMedia = true; # mount on /media/* instead of /run/media/$USER/*
  };

  # for Bluetooth
  services.blueman.enable = config.hardware.bluetooth.enable;

  # Compat for Unpriviledged Config ===========================================

  programs.dconf.enable = true; # Required for some gtk user config?

  # TTY Console Niceness ======================================================

  environment.etc."issue".source = ../../assets/etc-issue;

  console = {
    font = lib.mkDefault ""; # I want the default font, but I don't know what to put here for that, but this seems to work

    earlySetup = config.console.font != ""; # apply font in early initrd

    colors = [
      # Solarised w/ corrected bright colours
      "002b36" # base03
      "dc322f"
      "859900"
      "b58900"
      "268bd2"
      "d33682"
      "2aa198"
      "eee8d5" # base2

      "586e75" # base01
      "e35d5b"
      "b1cc00"
      "e8b000"
      "4ca2df"
      "dc609c"
      "35c9be"
      "fdf6e3" # base3
    ];
  };

}
