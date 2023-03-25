{ lib
, fetchgit
, stdenv
}:

stdenv.mkDerivation {
  pname = "numix-reborn-icon-themes";
  version = "2015-10-02";

  src = fetchgit {
    url = "https://gitlab.manjaro.org/artwork/themes/numix-reborn-manjaro-themes.git";
    rev = "4ca5a72a8d3ec3aecdc436f4860d2eb1bdf48d39";
    hash = "sha256-wRV02JFbblZ/gkR4fjXH361Bgu3HU2XQARIreC/tuuE=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons
    cp -r ./icon-theme/* $out/share/icons
    runHook postInstall
  '';
}
