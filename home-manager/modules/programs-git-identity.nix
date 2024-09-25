{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.git.identity;

  gitIniType = with types;
    let
      primitiveType = either str (either bool int);
      multipleType = either primitiveType (listOf primitiveType);
      sectionType = attrsOf multipleType;
      supersectionType = attrsOf (either multipleType sectionType);
    in
    attrsOf supersectionType;
in
{
  options.programs.git.identity = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        origins = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = "git@github.com:*/**";
          description = "Use the identity when the url of the origin remote matches this pattern.";
        };

        userName = mkOption {
          type = types.str;
          description = "User name to use.";
        };

        userEmail = mkOption {
          type = types.str;
          description = "User email to use.";
        };

        extraConfig = mkOption {
          type = gitIniType;
          default = { };
          description = "Additional configuration to add.";
        };
      };
    });
    default = { };
    description = "List of git identities";
  };

  config.programs.git = {
    aliases = mapAttrs'
      (name: c: {
        name = "id-${name}";
        value = "!git config --local user.name ${escapeShellArg c.userName} && git config --local user.email ${escapeShellArg c.userEmail}";
      })
      cfg;

    includes =
      let
        gen = origin: c: {
          condition = "hasconfig:remote.*.url:${origin}";
          contents = c.extraConfig // {
            user.name = c.userName;
            user.email = c.userEmail;
          };
        };
      in
      concatMap (ident: map (origin: gen origin ident) ident.origins) (attrValues cfg);
  };
}
