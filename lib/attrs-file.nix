{
  lib,
}:
{
  # file of attributes
  keys,
  # attribute set to get items from
  pkgs,
}:

let
  rawContents =
    if builtins.isPath keys then builtins.readFile keys
    else throw "keys is not a path";

  cleanLine = line:
    builtins.elemAt
      (builtins.match ''[[:space:]]*([^[:space:]]*)[[:space:]]*(#.*)?'' line)
      0;

  entries =
    lib.filter (x: x != "")
      (map cleanLine
        (lib.splitString "\n" rawContents));

  getAttr = key: lib.getAttrFromPath (lib.splitString "." key) pkgs;
in
  map getAttr entries
