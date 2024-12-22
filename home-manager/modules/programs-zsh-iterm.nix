{ config, lib, pkgs, ... }:
with lib;
{
  options.programs.zsh.itermIntegration = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Iterm2 shell integration, see <https://iterm2.com/documentation-shell-integration.html>";
  };

  config = mkIf config.programs.zsh.itermIntegration {
    programs.zsh.initExtra = let
      script = pkgs.fetchurl {
        name = "iterm2_shell_integration.zsh";
        url = "https://iterm2.com/shell_integration/zsh";
        hash = "sha256-Cq8winA/tcnnVblDTW2n1k/olN3DONEfXrzYNkufZvY=";
      };
    in
    mkAfter "source ${script}";
  };
}
