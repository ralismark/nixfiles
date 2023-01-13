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

}
