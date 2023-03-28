target: modules: {
  config = modules.${target} or throw "Module does not support target '${target}'";
}
