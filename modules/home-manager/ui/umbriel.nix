{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  defaults = builtins.fromTOML (builtins.readFile "${inputs.umbriel}/examples/config.toml");
  once = action: {
    inherit action;
    repeat = false;
  };
  locked = action: {
    inherit action;
    allow_when_locked = true;
  };
  # Noctalia's clipboard manager is disabled; copy captures through wl-copy.
  screenshot =
    mode:
    once "spawn noctalia msg screenshot-${mode} --no-annotate --no-save-to-file --no-copy-to-clipboard --pipe-to-command --pipe-command '${pkgs.wl-clipboard}/bin/wl-copy --type image/png'";
in
{
  imports = [ inputs.umbriel.homeModules.default ];

  programs.umbriel = {
    enable = true;
    settings = defaults // {
      general = defaults.general // {
        autostart = [
          "noctalia"
          "vicinae server"
        ];
      };
      input = lib.recursiveUpdate defaults.input {
        middle_click_paste = false;
        keyboard = {
          repeat_delay = 150;
          repeat_rate = 50;
        };
        touchpad = {
          tap = true;
          natural_scroll = true;
          scroll_factor = 0.25;
        };
        mouse.accel_profile = "flat";
        focus.follows_mouse = true;
        cursor.follows_focus = true;
      };
      layout = defaults.layout // {
        mode = "scrolling";
        gap = 4;
        extent_presets = [
          0.16667
          0.33333
          0.5
          0.66667
          0.83333
        ];
        struts = {
          left = 32;
          right = 32;
          top = 0;
          bottom = 0;
        };
        scrolling = {
          center_underfull_strip = true;
        };
      };
      workspaces.empty_above = true;

      scratchpad = [
        {
          name = "terminal";
          spawn_when_empty = "ghostty --class=dev.hackr.scratchterm";
          proportional_size = true;
        }
        {
          name = "obsidian";
          spawn_when_empty = "obsidian";
          proportional_size = true;
        }
      ];
      window_rule = defaults.window_rule ++ [
        {
          match.app_id = ''^dev\.hackr\.scratchterm$'';
          default_scratchpad = "terminal";
          default_floating_size = {
            width = 0.6;
            height = 0.6;
          };
        }
        {
          match.app_id = "^obsidian$";
          default_scratchpad = "obsidian";
          default_floating_size = {
            width = 0.8;
            height = 0.85;
          };
        }
      ];

      # Replace upstream bindings so its scratchpad and workspace shortcuts do
      # not conflict with the Niri chords below.
      keybinds = {
        "Mod+Shift+Ctrl+Slash" = once "cheatsheet-toggle";
        "Mod+Return" = once "spawn ghostty";
        "Mod+Shift+Space" = once "spawn noctalia msg panel-toggle launcher";
        "Mod+Space" = once "spawn vicinae toggle";
        "Mod+Grave" = "scratchpad-toggle terminal";
        "Mod+1" = "scratchpad-toggle obsidian";
        "Super+Alt+L" = once "spawn nautilus";

        "XF86AudioRaiseVolume" = locked "spawn wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.025+";
        "XF86AudioLowerVolume" = locked "spawn wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.025-";
        "XF86AudioMute" = locked "spawn wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" // {
          repeat = false;
        };
        "XF86AudioMicMute" = locked "spawn wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" // {
          repeat = false;
        };
        "XF86AudioPlay" = locked "spawn playerctl play-pause" // {
          repeat = false;
        };
        "XF86AudioPause" = locked "spawn playerctl play-pause" // {
          repeat = false;
        };
        "XF86AudioNext" = locked "spawn playerctl next";
        "XF86AudioPrev" = locked "spawn playerctl previous";
        "XF86MonBrightnessUp" = locked "spawn brightnessctl s 10%+";
        "XF86MonBrightnessDown" = locked "spawn brightnessctl s 10%-";

        "Mod+Q" = once "window-close";
        "Mod+Tab" = once "overview-toggle";

        "Mod+Left" = "window-focus-left";
        "Mod+Down" = "window-focus-down";
        "Mod+Up" = "window-focus-up";
        "Mod+Right" = "window-focus-right";
        "Mod+Ctrl+Left" = "window-focus-left";
        "Mod+Ctrl+Down" = "window-focus-down";
        "Mod+Ctrl+Up" = "window-focus-up";
        "Mod+Ctrl+Right" = "window-focus-right";

        "Mod+Ctrl+Equal" = "window-modify-primary-extent +0.025";
        "Mod+Ctrl+Minus" = "window-modify-primary-extent -0.025";
        "Mod+Alt+Ctrl+Left" = "window-consume-or-expel-left";
        "Mod+Alt+Ctrl+Right" = "window-consume-or-expel-right";
        "Mod+Alt+Ctrl+Up" = "window-move-up";
        "Mod+Alt+Ctrl+Down" = "window-move-down";

        "Mod+Home" = "column-focus-first";
        "Mod+End" = "column-focus-last";
        "Mod+Ctrl+Home" = "column-move-to-first";
        "Mod+Ctrl+End" = "column-move-to-last";

        "Mod+Shift+Left" = "output-focus-left";
        "Mod+Shift+Down" = "output-focus-down";
        "Mod+Shift+Up" = "output-focus-up";
        "Mod+Shift+Right" = "output-focus-right";
        "Mod+Shift+H" = "output-focus-left";
        "Mod+Shift+J" = "output-focus-down";
        "Mod+Shift+K" = "output-focus-up";
        "Mod+Shift+L" = "output-focus-right";

        "Mod+WheelDown" = "window-focus-right";
        "Mod+WheelUp" = "window-focus-left";
        "Mod+Ctrl+WheelDown" = "window-focus-down";
        "Mod+Ctrl+WheelUp" = "window-focus-up";
        "Mod+Shift+WheelDown" = "workspace-next";
        "Mod+Shift+WheelUp" = "workspace-previous";

        "Shift+Ctrl+Alt+F" = once "window-toggle-maximize";
        "Mod+Shift+Ctrl+F" = once "window-toggle-fullscreen";
        "Mod+Z" = "column-center";
        # Niri's center-visible-columns (Mod+Ctrl+Z) has no Umbriel action.
        "Mod+Ctrl+Space" = once "window-toggle-floating";
        "Mod+Ctrl+Alt+Space" = once "column-toggle-tabbed";
        "Mod+R" = "window-cycle-primary-extent";
        "Mod+Shift+R" = "window-cycle-primary-extent-back";

        "Mod+Ctrl+Shift+3" = screenshot "fullscreen";
        "Mod+Ctrl+Alt+Z" = screenshot "fullscreen";
        "Mod+Ctrl+Shift+4" = screenshot "region";
        "Mod+Ctrl+Alt+X" = screenshot "region";
        "Mod+Ctrl+Shift+5" = screenshot "window";
        "Mod+Ctrl+Alt+C" = screenshot "window";
        "Mod+Shift+5" = once "spawn noctalia msg screenshot-annotate";

        "Mod+Escape" = once "shortcuts-inhibit-toggle" // {
          allow_when_inhibited = true;
        };
        "Mod+Ctrl+Q" = once "session-quit";
        "Mod+Ctrl+Shift+Q" = once "dpms-off";
      };
    };
  };
}
