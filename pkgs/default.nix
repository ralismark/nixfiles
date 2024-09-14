self: super: {

  # Broken 2024-08-01. This is only really needed for IME popups
  # sway-unwrapped = (super.sway-unwrapped.overrideAttrs (prev: {
  #   version = "1.10-dev";
  #   src = self.fetchFromGitHub {
  #     owner = "swaywm";
  #     repo = "sway";
  #     rev = "7e74a4914261cf32c45017521960adf7ff6dac8f";
  #     hash = "sha256-rQuDnnmJHZB2ozErj1yUuYubVAozSl7Pyojr+ezzMIc=";
  #   };
  # })).override {
  #   # note that sway-unwrapped uses the wlroots_0_17 package by default
  #   wlroots = super.wlroots.overrideAttrs (prev: {
  #     version = "0.18.0-dev";
  #     src = self.fetchFromGitLab {
  #       domain = "gitlab.freedesktop.org";
  #       owner = "wlroots";
  #       repo = "wlroots";
  #       rev = "42673a282137ad4dc39b6a70c011dba4d822b85c";
  #       hash = "sha256-EnNYOYAl+e7LD1i2HocfFwc0az4vHthobWmadafuAso=";
  #     };
  #   });
  # };

  adapta-maia-theme = self.callPackage ./adapta-maia-theme { };


  font-droid = self.callPackage ./font-droid.nix { };

  numix-reborn-icon-themes = self.callPackage ./numix-reborn-icon-themes.nix { };

  pantheon = super.pantheon.overrideScope (self': super': {
    elementary-files = super'.elementary-files.overrideAttrs (prev: {
      mesonFlags = (prev.mesonFlags or [ ]) ++ [ "-Dwith-zeitgeist=disabled" ];
    });
  });

  qmk-udev-rules = super.qmk-udev-rules.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [
      (builtins.toFile "no-plugdev.patch" ''
        --- a/util/udev/50-qmk.rules
        +++ b/util/udev/50-qmk.rules
        @@ -65,7 +65,7 @@
         SUBSYSTEMS=="usb", ATTRS{idVendor}=="2a03", ATTRS{idProduct}=="0037", TAG+="uaccess", ENV{ID_MM_DEVICE_IGNORE}="1"

         # hid_listen
        -KERNEL=="hidraw*", MODE="0660", GROUP="plugdev", TAG+="uaccess", TAG+="udev-acl"
        +KERNEL=="hidraw*", TAG+="uaccess"

         # hid bootloaders
         ## QMK HID
      '')
    ];
  });

}
