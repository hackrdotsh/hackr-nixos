{
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
{
  imports = [
    ./niri.nix
    ./umbriel.nix
    ./noctalia.nix
    ./nocapture.nix
    inputs.vicinae.homeManagerModules.default
  ];

  home.packages =
    with pkgs;
    [
      cava
      playerctl
      brightnessctl
      wf-recorder
      slurp
      hyprpicker
      wl-clipboard
      pavucontrol
      pulseaudioFull
      alsa-utils
      # Light + dark GTK theme pair the noctalia toggle flips between (it sets
      # gtk-theme adw-gtk3 / adw-gtk3-dark alongside the color-scheme).
      adw-gtk3
    ]
    ++ (with inputs; [
      awww.packages.${system}.default
    ]);

  # Hand GTK/GNOME appearance to the runtime noctalia toggle. Stylix would
  # otherwise pin a single polarity: the gtk target writes a fixed gtk.css and
  # gtk-theme, and the gnome target pins color-scheme = prefer-dark in dconf,
  # both of which fight live light/dark switching.
  stylix.targets.gtk.enable = false;
  stylix.targets.gnome.enable = false;

  # Declarative login baseline = Pierre dark (matches noctalia darkMode = true).
  # The noctalia toggle overrides these live at runtime; they reset to dark on
  # relogin, which is the intended session-only behaviour.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
  };

  # Stylix points both vicinae theme slots at one (dark) generated theme, so it
  # can't switch. Use the dedicated Pierre dark/light themes instead; vicinae
  # picks the slot that matches the system color-scheme the toggle sets.
  stylix.targets.vicinae.enable = false;

  programs.vicinae = {
    enable = true;
    settings = {
      launcher_window.layer_shell.enabled = false;
      launcher_window.opacity = 1.0;
      theme.dark.name = "pierre-dark";
      theme.light.name = "pierre-light";
    };
    systemd = {
      enable = false;
      autoStart = false;
    };
  };

  # Qt reports colorScheme=Dark here (qt6ct's static palette never follows the
  # portal), so vicinae always reads the theme.dark slot. The noctalia
  # darkModeChange hook drives `vicinae theme set` to rewrite that slot live.
  # The vicinae module no longer symlinks settings.json (configFile = {}); the
  # server writes it itself at runtime, so it is already writable and the old
  # force/copy workaround is unnecessary. Declarative defaults above flow
  # through VICINAE_OVERRIDES.
}
