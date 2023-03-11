target: modules: {
  imports = modules.${target}.imports or [];
  options = modules.${target}.options or {};
  config = modules.${target}.config or {};
}
