{ adapta-gtk-theme
, fetchFromGitHub
}:
adapta-gtk-theme.overrideAttrs (final: prev: {
  pname = "adapta-maia-theme";
  version = "3.94.0.149";

  src = fetchFromGitHub {
    owner = "adapta-project";
    repo = "adapta-gtk-theme";
    rev = final.version;
    hash = "sha256-UbiVg1PScqPsWox+fRxzhg9eQTL+v2iZuZ78SLY/YOU=";
  };

  enableParallelBuilding = true;

  configureFlags = [
    # "--enable-gtk_next"
    # "--disable-gnome"
    # "--disable-cinnamon"
    # "--disable-flashback"
    # "--disable-xfce"
    # "--disable-mate"
    # "--disable-openbox"
  ];

  postPatch = (prev.postPatch or "") + ''
    find . -type f -name '*.*' -exec sed -i "s/#00BCD4/#16a085/Ig" {} \;

    find ./extra/gedit/adapta.xml \
        ./extra/plank/dock.theme \
      ./extra/telegram/dark/colors.tdesktop-theme \
      ./extra/telegram/light/colors.tdesktop-theme \
      ./gtk/asset/assets-gtk2.svg.in \
      ./gtk/asset/assets-gtk3.svg.in \
      ./gtk/asset/assets-clone/z-depth-1.svg \
      ./gtk/asset/assets-clone/z-depth-2.svg \
      ./gtk/gtk-2.0/colors.rc.in \
      ./gtk/gtk-2.0/colors-dark.rc.in \
      ./gtk/gtk-2.0/common.rc \
      ./gtk/gtk-2.0/common-eta.rc \
      ./gtk/sass/common/_colors.scss \
      ./m4/adapta-color-scheme.m4 \
      ./shell/asset/assets-cinnamon/ \
      ./shell/asset/assets-gnome-shell/ \
      ./shell/asset/assets-xfce/ \
      ./shell/sass/common/_colors.scss \
      ./shell/sass/gnome-shell/3.24/_extension-workspaces-to-dock.scss \
      ./shell/sass/gnome-shell/3.26/_extension-workspaces-to-dock.scss \
      ./shell/xfce-notify-4.0/gtkrc \
      ./wm/asset/assets-metacity/ \
      ./wm/asset/assets-openbox/ \
      ./wm/asset/assets-xfwm/ \
      ./wm/metacity-1/metacity-theme-2.xml \
      ./wm/openbox-3/themerc \
      ./wm/openbox-3/themerc-nokto \
      ./wm/xfwm4/themerc -type f -print | xargs sed -i -e \
      's/#2196F3/#38a8a3/Ig'  -e \
      's/#03A9f4/#299984/Ig'
  '';

  postInstall = (prev.postInstall or "") + ''
    # Move the file into another folder to match with name
    cd $out/share/themes
    mv Adapta Adapta-Maia
    mv Adapta-Nokto Adapta-Nokto-Maia
    mv Adapta-Eta Adapta-Eta-Maia
    mv Adapta-Nokto-Eta Adapta-Nokto-Eta-Maia

    # Modify the index theme
    sed -i -e 's,.*Adapta.*,Adapta-Maia,' $out/share/themes/Adapta-Maia/index.theme
    sed -i -e 's,.*Adapta-Nokto.*,Adapta-Nokto-Maia,' $out/share/themes/Adapta-Nokto-Maia/index.theme
    sed -i -e 's,.*Adapta-Eta.*,Adapta-Eta-Maia,' $out/share/themes/Adapta-Eta-Maia/index.theme
    sed -i -e 's,.*Adapta-Nokto-Eta.*,Adapta-Nokto-Eta-Maia,' $out/share/themes/Adapta-Nokto-Eta-Maia/index.theme

    # New symlink
    cd "$out/share/themes/Adapta-Nokto-Maia"
    ln -sf ../Adapta-Maia/xfwm4 xfwm4
    ln -sf ../Adapta-Maia/xfce-notify-4.0 xfce-notify-4.0
    ln -sf ../Adapta-Maia/plank plank
    ln -sf ../Adapta-Maia/gedit gedit
    ln -sf ../Adapta-Maia/metacity-1 metacity-1
    ln -sf ../Adapta-Maia/gtk-3.22 gtk-3.22
    ln -sf ../Adapta-Maia/gtk-3.0 gtk-3.0

    cd "$out/share/themes/Adapta-Eta-Maia"
    ln -sf ../Adapta-Maia/xfce-notify-4.0 xfce-notify-4.0
    ln -sf ../Adapta-Maia/plank plank
    ln -sf ../Adapta-Maia/telegram telegram
    ln -sf ../Adapta-Maia/metacity-1 metacity-1

    cd "$out/share/themes/Adapta-Nokto-Eta-Maia"
    ln -sf ../Adapta-Eta-Maia/gtk-3.22 gtk-3.22
    ln -sf ../Adapta-Maia/metacity-1 metacity-1
    ln -sf ../Adapta-Maia/plank plank
    ln -sf ../Adapta-Nokto-Maia/telegram telegram
    ln -sf ../Adapta-Maia/xfce-notify-4.0 xfce-notify-4.0
  '';
})
