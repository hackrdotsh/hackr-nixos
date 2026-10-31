{
  inputs,
  system,
  username,
  ...
}:
{
  imports = [ inputs.noctalia.homeModules.default ];

  # v5: no runtime colors.json anymore. The old `noctalia-shell` target only
  # wrote a static v4 palette that v5 ignores (kept off below as belt &
  # suspenders); the new `noctalia` target, however, would force a base16
  # palette + custom_palette="stylix", stylix fonts, opacity and wallpaper
  # defaults into our TOML, clobbering the palette source (Pierre custom /
  # wallpaper) and everything the runtime dark/light/auto toggle relies on.
  # Disabled, same reason we disable the gtk/gnome/vicinae targets.
  stylix.targets.noctalia-shell.enable = false;
  stylix.targets.noctalia.enable = false;

  programs.noctalia = {
    enable = true;
    package = inputs.noctalia.packages.${system}.default;

    # The attrset below is converted to TOML into ~/.config/noctalia/config.toml
    # and validated at build time (`noctalia config validate`). GUI changes made
    # at runtime are written to ~/.local/state/noctalia/settings.toml, which
    # loads AFTER config.toml and wins. If a setting here appears ignored,
    # clear the override from that state file. (No writable-copy activation
    # hack needed anymore; that was a v4 read-only-symlink workaround.)
    #
    # v4 -> v5 port notes:
    # - plugins are Luau now, addressed <author>/<plugin>; official/community
    #   sources are built in, no source declaration needed.
    # - polkit-agent is built into the shell ([shell] polkit_agent).
    # - display-settings and model-usage have no v5 equivalent (see journal).
    settings = {
      accessibility = {
        ui_scale = 1.0;
        high_contrast = false;
      };

      shell = {
        font_family = "DM Sans";
        corner_radius_scale = 0.0;
        telemetry_enabled = false;
        settings_show_advanced = true;
        # Replaces the v4 polkit-agent plugin. modules/nixos/security/polkit.nix
        # intentionally installs no standalone agent.
        polkit_agent = true;
        avatar_path = "/home/${username}/.face";
        # Attached panels anchor to this bar (relevant once multiple bars exist).
        panel_anchor_bar = "main";
        password_style = "random";
        # v4 clipboard history was off and piped through cliphist; v5 has a
        # built-in (encrypted) clipboard manager. Keeping the v4 behaviour of
        # "no clipboard history" here. Flip to true to get the new one.
        clipboard_enabled = false;
        # v4 time was 24h everywhere (use12hourFormat=false).
        time_format = "{:%H:%M}";

        mpris.blacklist = [ ]; # v4 audio.mprisBlacklist

        animation = {
          enabled = true; # v4 animationDisabled = false
          speed = 1.0;
        };

        shadow = {
          direction = "down_right"; # v4 shadowDirection "bottom_right"
          alpha = 0.55; # default; v4 enableShadows=true mapped to per-surface shadow flags
        };

        panel = {
          transparency_mode = "glass"; # live-tweaked from "soft" (~ v4 ui.panelBackgroundOpacity 0.93; no numeric knob in v5)
          launcher_position = "center"; # v4 appLauncher.position "center" (placement floating = default)
          control_center_placement = "attached"; # v4 ui.panelsAttachedToBar
          clipboard_placement = "attached";
          polkit_placement = "attached";
          wallpaper_placement = "attached"; # v4 wallpaper.panelPosition "follow_bar"
          open_near_click_control_center = true; # v4 controlCenter.position "close_to_bar_button"
          session_placement = "floating";
          session_position = "center"; # v4 sessionMenu.position "center"
        };

        launcher = {
          categories = true; # v4 showCategories
          show_icons = true; # v4 iconMode "tabler" (v5 icons are tabler-style regardless)
          app_grid = false; # v4 viewMode "list"
          sort_by_usage = true; # v4 sortByMostUsed
        };

        session = {
          grid = true; # v4 largeButtonsLayout "grid"
          show_shortcuts = true; # v4 showNumberLabels
          # v4 countdown (10000ms) is per-action in v5. v4 order preserved.
          # v5 has no hibernate action; emulated with a custom command.
          actions = [
            {
              action = "lock";
              countdown_seconds = 10;
            }
            {
              action = "suspend";
              countdown_seconds = 10;
            }
            {
              action = "command";
              label = "Hibernate";
              glyph = "bedtime";
              command = "systemctl hibernate";
              countdown_seconds = 10;
            }
            {
              action = "reboot";
              countdown_seconds = 10;
              variant = "destructive";
            }
            {
              action = "logout";
              countdown_seconds = 10;
            }
            {
              action = "shutdown";
              countdown_seconds = 10;
              variant = "destructive";
            }
          ];
        };
      };

      wallpaper = {
        enabled = true;
        directory = "/home/${username}/walls";
        fill_mode = "crop";
        fill_color = "#000000";
        # `transition` omitted: v5 picks randomly from the full pool
        # (fade/wipe/disc/stripes/zoom/honeycomb) == v4 transitionType "random".
        transition_duration = 1500;
        edge_smoothness = 0.05;

        automation = {
          enabled = false; # v4 automationEnabled
          interval_seconds = 300; # v4 randomIntervalSec
          order = "random"; # v4 wallpaperChangeMode
        };
      };

      theme = {
        # Live GUI moved the baseline off mode="dark" + source="custom" (Pierre)
        # onto auto dark/light (sunrise/sunset from [location]) with colors
        # pulled from the current wallpaper and a pure-black dark surface. The
        # theme_mode_changed hook still tracks the resolved mode. Pierre stays
        # as the preselected custom palette in case source flips back.
        mode = "auto";
        source = "wallpaper";
        pure_black_dark = true;
        custom_palette = "Pierre";

        templates = {
          enable_builtin_templates = false;
          enable_community_templates = false;
        };
      };

      hooks = {
        # v4 hooks.darkModeChange. In v5 the payload is an env var:
        # NOCTALIA_THEME_MODE = dark|light (resolved), not positional $1.
        # Drives every app that follows the freedesktop appearance portal
        # (ghostty, zed, gtk/gnome) plus vicinae's pierre themes.
        theme_mode_changed = ''
          if [ "$NOCTALIA_THEME_MODE" = "dark" ]; then
            gsettings set org.gnome.desktop.interface color-scheme prefer-dark
            gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
            vicinae theme set pierre-dark || true
          else
            gsettings set org.gnome.desktop.interface color-scheme prefer-light
            gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
            vicinae theme set pierre-light || true
          fi
        '';
      };

      notification = {
        enable_daemon = true;
        layer = "overlay"; # v4 overlayLayer
        background_opacity = 1.0;
        # (v4 was top_right = v5 default; per-urgency durations/respectExpiry
        # don't exist in v5; sender expire_timeout is honored, else 6s.)
      };

      osd = {
        enabled = true; # v4 osd.enabled
        position = "top_right";
        background_opacity = 1.0;

        # v4 enabledTypes [0 1 2] = volume-out + volume-in + brightness;
        # keyboard_layout carries over v4's notifications.enableKeyboardLayoutToast.
        # The six extra kinds (wifi/bluetooth/power_profile/caffeine/nightlight/dnd)
        # were turned on in the live GUI; lock_keys/keyboard_backlight/privacy
        # stay off.
        kinds = {
          volume = true;
          volume_output = true;
          volume_input = true;
          brightness = true;
          lock_keys = false;
          keyboard_layout = true;
          keyboard_backlight = false;
          wifi = true;
          bluetooth = true;
          power_profile = true;
          caffeine = true;
          nightlight = true;
          dnd = true;
          privacy = false;
        };
      };

      weather = {
        enabled = true;
        refresh_minutes = 30;
        unit = "metric"; # v4 useFahrenheit=false ("metric|imperial", not celsius/fahrenheit)
        effects = true; # v4 weatherShowEffects
      };

      location = {
        auto_locate = false;
        address = "Calgary, AB"; # v4 location.name (geocoded once, feeds weather + nightlight schedule)
      };

      nightlight = {
        enabled = true;
        temperature_day = 6500; # v4 dayTemp
        temperature_night = 2500; # v4 nightTemp
        force = false; # v4 forced
        # Schedule: v4 autoSchedule=true -> v5 computes sunrise/sunset from
        # [location]. (To force times instead: location.custom_schedule + sunrise/sunset.)
      };

      brightness = {
        enable_ddcutil = false; # v4 enableDdcSupport
        minimum_brightness = 0.05; # v4 enforceMinimum -- hard floor instead of v4's clamp
      };

      audio = {
        enable_overdrive = false; # v4 volumeOverdrive
        enable_sounds = false; # v4 notification/plugin sounds all off
        sound_volume = 0.5;
      };

      system.monitor = {
        enabled = true;
        cpu_poll_seconds = 1;
        gpu_poll_seconds = 3;
        memory_poll_seconds = 1;
        network_poll_seconds = 1;
        disk_poll_seconds = 30; # v4 ms values converted (loadAvg merged into cpu)
        # v4 warning/critical thresholds -> v5 activity/critical per-stat.
        cpu_usage_activity_threshold = 80;
        cpu_usage_critical_threshold = 90;
        gpu_usage_activity_threshold = 80;
        gpu_usage_critical_threshold = 90;
        gpu_temp_activity_threshold = 80;
        gpu_temp_critical_threshold = 90;
        cpu_temp_activity_threshold = 80;
        cpu_temp_critical_threshold = 90;
        ram_pct_activity_threshold = 80;
        ram_pct_critical_threshold = 90;
        swap_pct_activity_threshold = 80;
        swap_pct_critical_threshold = 90;
        disk_used_pct_activity_threshold = 80;
        disk_used_pct_critical_threshold = 90;
      };

      battery.warning_threshold = 20; # v4 batteryWarningThreshold (drives low-battery notify)

      dock.radius = 0;

      control_center = {
        # v5 shows max 6 (flat list; no left/right split). v4 had 8:
        # kept wifi, bluetooth, wallpaper, notification, nightlight, dark_mode;
        # dropped power_profile + caffeine (swap back any of the others if wanted).
        shortcuts = [
          { type = "wifi"; }
          { type = "bluetooth"; }
          { type = "wallpaper"; }
          { type = "notification"; }
          { type = "nightlight"; }
          { type = "dark_mode"; }
        ];
      };

      bar.main = {
        position = "top";
        # Floating rectangular bar: more transparent with square corners,
        # always visible with space reserved so windows do not overlap it.
        # The tinted surface follows the palette (flips with dark/light) and
        # keeps widgets readable over busy wallpapers. v4 was 0 (fully
        # transparent) with radius 12; the Nix baseline was 0.65/12/reserved.
        background_opacity = 0.5;
        radius = 0;
        margin_ends = 36; # Match Niri's 32px side struts + 4px gaps.
        margin_edge = 5; # v4 marginVertical
        padding = 8; # v4 frameThickness
        widget_spacing = 6;
        # v4 showCapsule=true but capsuleColorKey="none" = invisible capsule ->
        # capsule widgets would be see-through anyway; plain floating bar is the
        # same look. Set capsule=true (+capsule_fill) if you want capsules back.
        capsule = false;
        capsule_radius = 0.0;
        reserve_space = true;
        auto_hide = false;
        smart_auto_hide = false;

        start = [ ];
        center = [ "active_window" ];
        end = [
          "mawaqit" # ycf/mawaqit:bar (widget table below)
          "tray"
          "notifications"
          "clock"
        ];
      };

      widget = {
        active_window = {
          display = "icon_and_text"; # v4 showIcon
          max_length = 450; # v4 maxWidth (px)
          title_scroll = "on_hover"; # v4 scrollingMode "hover"
          show_empty_label = false; # v4 hideMode "hidden"
        };

        workspaces = {
          style = "regular";
          show_labels = true;
          label_source = "id"; # v4 labelMode "index" (niri workspace numbering)
          max_label_chars = 2; # v4 characterCount
          labels_only_when_occupied = true; # v4 showLabelsOnlyWhenOccupied
          hide_when_empty = false; # v4 hideUnoccupied=false
          # v4 pillSize=0.6 has no 1:1 equivalent -- v5 splits it into a global
          # pill_scale plus active/inactive pill multipliers (defaults 1.0/2.2/1.0,
          # i.e. the focused pill is 2.2x the dot). Scaling everything by 0.6
          # squishes the active pill, so leave the defaults alone.
          focused_color = "primary";
          occupied_color = "secondary";
          empty_color = "secondary";
          urgent_color = "error";
        };

        # Bar widget entries for plugins: type = "<author>/<plugin>:<entry>".
        mawaqit = {
          type = "ycf/mawaqit:bar";
          showCountdown = false;
          hidePrayerName = true;
          showElapsed = false;
          dynamicIcon = true;
          widgetIcon = "pray";
        };

        tray = {
          drawer = true; # v4 drawerEnabled
          pinned = [ ];
          hidden = [ ]; # v4 blacklist
        };

        notifications.hide_when_no_unread = true; # v4 hideWhenZero

        battery = {
          display_mode = "glyph";
          show_label = true; # v4 displayMode "onhover" has no v5 equivalent -- always show
          label_content = "percent";
          device = "auto"; # v4 deviceNativePath "__default__"
        };

        volume = {
          show_label = true; # see battery note
          actions.middle = "exec pwvucontrol || pavucontrol"; # v4 middleClickCommand
        };

        brightness.show_label = true; # see battery note

        clock = {
          format = "{:%H:%M %a, %b %d}"; # v4 formatHorizontal
          vertical_format = "{:%H %M - %d %m}"; # v4 formatVertical
          tooltip_format = "{:%H:%M %a, %b %d}"; # v4 tooltipFormat
          font_family = "DepartureMono Nerd Font"; # v4 fontFixed (v5: per-widget only)
        };
      };

      plugins = {
        enabled = [
          "ycf/mawaqit"
          "hackrdotsh/nocapture"
        ];
        auto_update = "none";
      };

      # v4 plugin settings (from ~/.config/noctalia/plugins/mawaqit/settings.json).
      # Select-type values are strings in v5: method "2" = ISNA, school "0" = Shafi.
      plugin_settings."ycf/mawaqit" = {
        city = "Calgary";
        country = "CA";
        method = "2";
        school = "0";
        hijriDayOffset = "0";
        twelveHourFormat = false;
        showNotifications = true;
        playAzan = false;
        azanFile = "azan1.mp3";
        tune = false;
      };

      # v4 desktopWidgets (eDP-1 had Clock + Weather). cx/cy are the widget
      # center in logical px. Binary clock style: not in v5.
      desktop_widgets = {
        enabled = true;
        widget_order = [
          "clock_main"
          "weather_main"
        ];

        widget.clock_main = {
          type = "clock";
          output = "eDP-1";
          cx = 960.0;
          cy = 640.0;
          settings = {
            format = "{:%H:%M}\n{:%e %B %Y}"; # v4 "HH:mm\nd MMMM yyyy"
            color = "primary"; # v4 usePrimaryColor
            background = false; # v4 showBackground
          };
        };

        widget.weather_main = {
          type = "weather";
          output = "eDP-1";
          cx = 120.0; # ~ v4 x=20,y=60
          cy = 90.0;
          settings.background = false;
        };
      };

      # v4's big lockscreen clock (clockStyle custom, "hh\nmm"; 12h there while
      # the bar stayed 24h) plus the login box; both were placed in v5's edit
      # mode live, geometry persisted here.
      lockscreen_widgets = {
        enabled = true;
        widget_order = [
          "lockscreen-login-box@eDP-1"
          "big_clock"
        ];

        # Edit-mode snapping grid (persisted from live edit mode).
        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };

        widget."lockscreen-login-box@eDP-1" = {
          type = "login_box";
          output = "eDP-1";
          box_width = 810.0;
          box_height = 196.0;
          cx = 960.0;
          cy = 1098.0;
          settings = {
            layout = "regular";
            background_color = "surface_variant";
            background_opacity = 0.88;
            background_radius = 0.0;
            center_password_text = false;
            input_opacity = 1.0;
            input_radius = 0.0;
            show_caps_lock = true;
            show_keyboard_layout = true;
            show_login_button = true;
            show_media = true;
            show_session_buttons = true;
            show_unlock_hint = true;
            show_weather = true;
          };
        };

        widget.big_clock = {
          type = "clock";
          output = "eDP-1";
          cx = 960.0; # approx (center-ish, upper third) -- nudge in edit mode
          cy = 270.0;
          settings = {
            format = "{:%I}\n{:%M}"; # v4 "hh\nmm"
            color = "primary";
            background = false;
          };
        };
      };
    };
  };

  # Palette moved to the v5 layout (~/.config/noctalia/palettes/<Name>.json,
  # flat -- no per-name directory). The JSON shape is unchanged from v4.
  programs.noctalia.customPalettes.Pierre = ../../../cfg/noctalia/palettes/Pierre.json;

  # v4 runtime leftovers kept untouched in ~/.config/noctalia: settings.json,
  # colors.json(.bak), plugins.json(.bak), plugins/ (QML), colorschemes/.
  # Shell v5 ignores them; safe to `rm` manually once happy with v5.
}
