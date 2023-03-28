target: modules:
if !(modules ? ${target}) then throw "Module does not support target '${target}'"
else {
  imports = modules.${target}.imports or [];
  options = modules.${target}.options or {};
  config = modules.${target}.config or {};
}
