self: super: {

  sway-unwrapped = super.sway-unwrapped.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [
      (self.fetchurl {
        url = "https://aur.archlinux.org/cgit/aur.git/plain/0001-text_input-Implement-input-method-popups.patch?h=9bba3fb267a088cca6fc59391ab45ebee654ada1";
        hash = "sha256-kqr9sHnk2wgfkC7so1y0EVVPd9kII3Oys/t2zmF2Q2c=";
      })
      (self.fetchurl {
        url = "https://aur.archlinux.org/cgit/aur.git/plain/0002-backport-sway-im-to-v1.8.patch?h=9bba3fb267a088cca6fc59391ab45ebee654ada1";
        hash = "sha256-MAKXW2StUX6ZqNtmwJhg5d39CiN4FMsi0m3H8uSp2B8=";
      })
    ];
  });

  adapta-maia-theme = self.callPackage ./adapta-maia-theme { };

  deepfilter-ladspa = self.callPackage ./deepfilter-ladspa { };

  font-droid = self.callPackage ./font-droid.nix { };

  numix-reborn-icon-themes = self.callPackage ./numix-reborn-icon-themes.nix { };

  pantheon = super.pantheon.overrideScope' (self': super': {
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

  waybar = super.waybar.overrideAttrs (prev: {
    mesonFlags = (prev.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
  });

  ranger = super.ranger.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [
      # https://github.com/ranger/ranger/issues/2583#issuecomment-1097438886
      (self.fetchurl {
        url = "https://github.com/ranger/ranger/commit/642d594b8328880d73d151852e4e41e7675ded6c.diff";
        hash = "sha256-rPM0jKm1ONI0ld+Cfu6/QnoIwdPDyTeOG0Fr01E9Q0s=";
      })
      (self.fetchurl {
        url = "https://github.com/ranger/ranger/commit/82eef55b1664a66c774df969673435eb7bc82091.diff";
        hash = "sha256-6ibvZvL8GyU4S9SNR3IXcjM2K1QVRBRESBP4vjQ8I2o=";
      })
    ];
  });

}
