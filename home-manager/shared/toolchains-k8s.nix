{ lib, pkgs, config, ... }:
with lib;
{
  home.packages = with pkgs; [
    k9s
    kubectl
    kubernetes-helm
  ];

  home.shellAliases.kubectx = "kubectl config use-context";
}
