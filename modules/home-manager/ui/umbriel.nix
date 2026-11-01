{ inputs, ... }:
let
  defaults = builtins.fromTOML (builtins.readFile "${inputs.umbriel}/examples/config.toml");
in
{
  imports = [ inputs.umbriel.homeModules.default ];

  programs.umbriel = {
    enable = true;
    settings = defaults // {
      general = defaults.general // {
        autostart = [ "noctalia" ];
      };
      keybinds = defaults.keybinds // {
        "Mod+Return" = {
          action = "spawn ghostty";
          repeat = false;
        };
      };
    };
  };
}
