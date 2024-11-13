self: super:

let
  wlroots = super.wlroots.overrideAttrs (prev: {
    version = "unstable-2024-09-12";
    src = self.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "wlroots";
      repo = "wlroots";
      rev = "7debaced03ee466a18a9bc220fa90a49d5aa9704";
      hash = "sha256-7f93uVTGVbqZo79U6WdClwpV1qQMWzt8P9t0yRlMPTY=";
    };
  });

  sway = super.sway-unwrapped.override { inherit wlroots; };
in

  sway.overrideAttrs (prev: {
    version = "unstable-2024-09-13";
    src = self.fetchFromGitHub {
      owner = "swaywm";
      repo = "sway";
      rev = "f957c7e658871c27935f88f6e1d18b9db67f3808";
      hash = "sha256-Xu3WBtCk5zTDViVTW2q3fWuB4kfPqMwZFUeVsU/j+h0=";
    };

    mesonFlags =
      builtins.filter
        (flag: !self.lib.strings.hasPrefix "-Dxwayland=" flag)
        prev.mesonFlags;
  })
