self: super: {

  sway-unwrapped = (super.sway-unwrapped.overrideAttrs (prev: {
    version = "1.10-dev";
    src = self.fetchFromGitHub {
      owner = "swaywm";
      repo = "sway";
      rev = "59f629238309e230b0e353e73d4f37a7de7fe820";
      hash = "sha256-AQor/lF83q3up1B3Eizcfm7bmhDkqHgf4ljoqsXXgrw=";
    };
  })).override {
    # note that sway-unwrapped uses the wlroots_0_17 package by default
    wlroots = super.wlroots.overrideAttrs (prev: {
      version = "0.18.0-dev";
      src = self.fetchFromGitLab {
        domain = "gitlab.freedesktop.org";
        owner = "wlroots";
        repo = "wlroots";
        rev = "22178451f7f5f0ad152e1dedf39b244500f24afb";
        hash = "sha256-rQuDnnmJHZB2ozErj1yUuYubVAozSl7Pyojr+ezzMIc=";
      };
    });
  };

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
