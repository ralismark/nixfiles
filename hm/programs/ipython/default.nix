{ ... }:
{
  xdg.configFile = {
    "ipython/profile_default/startup".source = ./startup;

    # TODO where to find docs for this
    "ipython/profile_default/ipython_config.py".text = ''
      ## A list of dotted module names of IPython extensions to load.
      c.InteractiveShellApp.extensions = ["autoreload"]
    '';
  };
}
