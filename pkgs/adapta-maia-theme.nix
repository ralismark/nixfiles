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
    "--disable-cinnamon"
    "--disable-flashback"
    "--disable-xfce"
    "--disable-mate"
    "--disable-openbox"
  ];

  patches = (prev.patches or []) ++ [
#    (builtins.toFile "parser-error-fix.patch" ''
#      diff --git a/gtk/sass/3.20/_misc.scss b/gtk/sass/3.20/_misc.scss
#      index b3ba2ba5..53895a4d 100644
#      --- a/gtk/sass/3.20/_misc.scss
#      +++ b/gtk/sass/3.20/_misc.scss
#      @@ -351,6 +351,7 @@ list.tweak-group-startup {
#       //  * Nautilus *
#       //  ************/
#
#      +/*
#       .nautilus-desktop-window {
#         &,
#         notebook,
#      @@ -496,6 +497,7 @@ dialog.background.csd > box.dialog-vbox > grid.horizontal {
#         }
#       }
#
#      +*/
#
#       // /*********
#       //  * Geary *
#      diff --git a/gtk/sass/3.22/_misc.scss b/gtk/sass/3.22/_misc.scss
#      index 0b97478b..4dd56efb 100644
#      --- a/gtk/sass/3.22/_misc.scss
#      +++ b/gtk/sass/3.22/_misc.scss
#      @@ -460,6 +460,7 @@ dialog.background.csd > box.dialog-vbox.vertical {
#       //  * Nautilus *
#       //  ************/
#
#      +/*
#       .nautilus-desktop-window {
#         &,
#         notebook,
#      @@ -633,6 +634,7 @@ dialog.background.csd > box.dialog-vbox > grid.horizontal {
#
#       .documents-entry-tag { @extend .entry-tag; }
#
#      +*/
#
#       // /*********
#       //  * Geary *
#      diff --git a/gtk/sass/3.24/_misc.scss b/gtk/sass/3.24/_misc.scss
#      index ba4cb7ba..af35d3c5 100644
#      --- a/gtk/sass/3.24/_misc.scss
#      +++ b/gtk/sass/3.24/_misc.scss
#      @@ -460,6 +460,7 @@ dialog.background.csd > box.dialog-vbox.vertical {
#       //  * Nautilus *
#       //  ************/
#
#      +/*
#       .nautilus-desktop-window {
#         &,
#         notebook,
#      @@ -666,6 +667,7 @@ dialog.background.csd > box.dialog-vbox > grid.horizontal {
#
#       .documents-entry-tag { @extend .entry-tag; }
#
#      +*/
#
#       // /*********
#       //  * Geary *
#      diff --git a/gtk/sass/4.0/_misc.scss b/gtk/sass/4.0/_misc.scss
#      index a3126a1e..446a58c6 100644
#      --- a/gtk/sass/4.0/_misc.scss
#      +++ b/gtk/sass/4.0/_misc.scss
#      @@ -459,6 +459,7 @@ dialog.background.csd > box.dialog-vbox.vertical {
#       //  * Nautilus *
#       //  ************/
#
#      +/*
#       .nautilus-desktop-window {
#         &,
#         notebook,
#      @@ -651,6 +652,7 @@ dialog.background.csd > box.dialog-vbox > grid.horizontal {
#
#       .documents-entry-tag { @extend .entry-tag; }
#
#      +*/
#
#       // /*********
#       //  * Geary *
#    '')
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
