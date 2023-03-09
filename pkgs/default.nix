self: super: {

  numix-reborn-icon-themes = self.callPackage ./numix-reborn-icon-themes.nix { };

  adapta-maia-theme = self.callPackage ./adapta-maia-theme.nix { };

  font-droid = self.callPackage ./font-droid.nix { };

  pantheon = super.pantheon.overrideScope' (self': super': {
    elementary-files = super'.elementary-files.overrideAttrs (prev: {
      mesonFlags = (prev.mesonFlags or [ ]) ++ [ "-Dwith-zeitgeist=disabled" ];
    });
  });

  waybar = super.waybar.overrideAttrs (prev: {
    mesonFlags = (prev.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
  });

  qmk-udev-rules = super.qmk-udev-rules.overrideAttrs (prev: {
    patches = (prev.patchs or [ ]) ++ [
      (builtins.toFile "no-plugdev.patch" ''
        --- a/util/udev/50-qmk.rules	1970-01-01 10:00:01.000000000 +1000
        +++ b/util/udev/50-qmk.rules	1970-01-01 10:00:01.000000000 +1000
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
