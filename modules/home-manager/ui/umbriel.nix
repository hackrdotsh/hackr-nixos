{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  defaults = builtins.fromTOML (builtins.readFile "${inputs.umbriel}/examples/config.toml");
  laptop = hostname == "snorlax" || hostname == "flareon";
  configDir = "${config.xdg.configHome}/umbriel";
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
          "1password --silent"
          "tailscale-systray"
        ]
        ++ lib.optional laptop "slack";
        xwayland_native_resolution = true;
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
        cursor = {
          follows_focus = true;
          theme = "BreezeX-RosePine-Linux";
        };
      };
      output = {
        "LG Electronics LG ULTRAGEAR+ 503NTNH4U183" = {
          mode = "5120x2160@165.058";
          scale = 1.0;
          position = [
            0
            0
          ];
        };
      }
      // lib.optionalAttrs laptop {
        "China Star Optoelectronics Technology Co., Ltd MND508ZB1-1 Unknown" = {
          mode = "2880x1920@120.000";
          scale = 1.5;
          position = [
            0
            0
          ];
          layout.scrolling.default_extent_fraction = 1.0;
        };
        "AU Optronics 0x749D Unknown" = {
          mode = "3840x2160@144.001";
          scale = 1.25;
          position = [
            7680
            0
          ];
          layout.scrolling.default_extent_fraction = 1.0;
        };
        "DP-4" = {
          mode = "3840x2160@29.970";
          scale = 1.0;
          position = [
            3840
            0
          ];
        };
        "HDMI-A-1" = {
          mode = "3840x2160@60.000";
          scale = 1.0;
          position = [
            0
            0
          ];
        };
        "DP-1" = {
          mode = "3840x2160@60.000";
          scale = 1.0;
          position = [
            3840
            0
          ];
        };
        "DP-2" = {
          mode = "3840x2160@60.000";
          scale = 1.0;
          position = [
            0
            0
          ];
        };
      };
      appearance = lib.recursiveUpdate defaults.appearance {
        prefer_no_csd = true;
        border_width = 2;
        corner_radius = 0;
        shadow.enabled = false;
        blur = {
          enabled = true;
          passes = 3;
          # Umbriel's radius is integral; Niri used offset 2.5.
          radius = 3;
          noise = 0.02;
          saturation = 1.25;
          brightness = 1.0;
          contrast = 1.0;
        };
        tab_bar = {
          style = "indicator";
          position = "left";
          height = 8;
          gap = 0;
          tab_gap = 0;
          corner_radius = 0;
        };
      };
      colors = {
        # Umbriel borders do not support Niri's two-color focus gradient.
        border = {
          focused = "#3d434c";
          unfocused = "#18191d";
        };
        tab_bar = {
          active = "#4d525a";
          active_unfocused = "#171717";
          background = "#171717";
          urgent = "#4e2c2c";
        };
        overview = {
          background_tint = "#171717";
          workspace_background = "#00000000";
        };
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
          match.is_floating = true;
          blur_optimized = false;
        }
        {
          match.is_focused = false;
          opacity = 0.85;
        }
        {
          match.is_focused = true;
          opacity = 1.0;
        }
        {
          match = {
            app_id = [
              "zen$"
              "zen-twilight$"
            ];
            title = "^Picture-in-Picture$";
          };
          default_focused = false;
        }
        {
          match.app_id = [
            "^org.gnome.NautilusPreviewer$"
            "^zab$"
            "^mongolore$"
          ];
          default_floating = true;
        }
        {
          match.app_id = "^org.pulseaudio.pavucontrol$";
          default_floating = true;
          # Umbriel can set the opening size, not Niri's minimum size.
          default_floating_size_px = {
            width = 800;
            height = 600;
          };
        }
        {
          match.app_id = "steam_app_1808500";
          default_fullscreen = true;
        }
        {
          match.app_id = "1password";
          block_capture = true;
        }
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

  xdg.configFile."umbriel/config.toml" = {
    target = "umbriel/config-settings.toml";
    force = true;
  };

  # Keep the live config editable; rebuilds restore the declarative baseline.
  home.activation.linkUmbrielSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${lib.getExe config.programs.umbriel.package} config validate -c ${lib.escapeShellArg "${configDir}/config-settings.toml"}
    run ${pkgs.coreutils}/bin/install -m 0644 -T -- \
      ${lib.escapeShellArg "${configDir}/config-settings.toml"} \
      ${lib.escapeShellArg "${configDir}/config.toml"}
  '';
}
