{ lib, pkgs, config, ... }:
with lib;
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
  ];

  home.shellAliases.kluster = "kubectl config use-context";

  programs.k9s = {
    enable = true;

    settings.k9s = {
      ui.logoless = true;
      skipLatestRevCheck = false;
    }
  };
}
