{ config, lib, ... }:
with lib;
let
  cfg = config.programs.zsh.bindkey;

  bindSource = k: v:
    if v.terminfo == null then escapeShellArg k
    else "\"\${terminfo[${v.terminfo}]}\"";

  mkBind = k: v: optionalString (v.target != null) ''
    ${v.initExtra}
    ${optionalString (v.terminfo != null) "[[ -n ${bindSource k v} ]] && "}bindkey ${bindSource k v} ${v.target}
  '';
in
{
  options.programs.zsh.bindkey = mkOption {
    type = types.attrsOf (types.submodule (
      { name, config, ... }: {
        options = {
          terminfo = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "kcbt";
            description = ''
              Terminfo capability entry corresponding to the code for this key.
              See man:terminfo(5) for a listing of available codes.
            '';
          };

          widget = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "backward-kill-word";
            description = "Widget to invoke";
          };

          script = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "builtin cd .. && zle reset-propt";
            description = "Shell script to run";
          };

          initExtra = mkOption {
            type = types.lines;
            description = ''
              Extra code to run before making the binding.
            '';
          };

          target = mkOption {
            type = types.nullOr types.str;
            default = null;
            visible = false;
            description = "Second argument to bindkey";
          };
        };

        config = mkMerge [
          (mkIf (config.widget != null) {
            # see man:zshzle(1)
            initExtra = ''
              if ! zle -la ${config.widget}; then
                autoload -U ${config.widget}
                zle -N ${config.widget}
              fi
            '';
            target = config.widget;
          })
          (mkIf (config.script != null) rec {
            target = ".bindkey-fn.${builtins.hashString "sha256" config.script}";
            initExtra = ''
              ${target}() {
              ${config.script}
              }
              zle -N ${target}
            '';
          })
        ];
      }
    ));
    default = { };
    description = "ZLE bindings";
  };

  config.programs.zsh.initExtra = ''
    ${concatStringsSep "\n" (mapAttrsToList mkBind cfg)}
  '';

  config.programs.zsh.bindkey = {
    C-Tab.terminfo = "kcbt";

    Up.terminfo = "kcuu1";
    Down.terminfo = "kcud1";
    Left.terminfo = "kcub1";
    Right.terminfo = "kcuf1";
    C-Up.terminfo = "kUP5";
    C-Down.terminfo = "kDN5";
    C-Left.terminfo = "kLFT5";
    C-Right.terminfo = "kRIT5";

    Delete.terminfo = "kdch1";
    End.terminfo = "kend";
    Home.terminfo = "khome";
    Insert.terminfo = "kich1";
    PageDown.terminfo = "knp";
    PageUp.terminfo = "kpp";
  };
}
