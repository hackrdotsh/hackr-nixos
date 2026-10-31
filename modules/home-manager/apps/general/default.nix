{
  pkgs,
  lib,
  inputs,
  system,
  pkgs-fresh,
  pkgs-stable,
  ...
}: let
  addons = pkgs.extend inputs.firefox-addons.overlays.default;
  jetbrainsApps = with pkgs-stable.jetbrains; [
    # datagrip
    # rider
    # rust-rover
    # idea
  ];
  # NOTE: requires manual download of affinity apps.
  # affinity-v3 is unfree; use the overlay on our allowUnfree pkgs (see affinity-nix README).
  # affinity = pkgs.extend inputs.affinity-nix.overlays.default;
  # affinityApps = with affinity; [
  #   affinity-v3
  # ];
  browsers = with pkgs-stable; [
    # ungoogled-chromium
    firefox
  ];
  krisp-patcher =
    pkgs.writers.writePython3Bin "krisp-patcher"
    {
      libraries = with pkgs.python3Packages; [
        capstone
        pyelftools
      ];
      flakeIgnore = [
        "E501" # line too long (82 > 79 characters)
        "F403" # 'from module import *' used; unable to detect undefined names
        "F405" # name may be undefined, or defined from star imports: module
      ];
    }
    (
      builtins.readFile (
        pkgs.fetchurl {
          url = "https://pastebin.com/raw/8tQDsMVd";
          sha256 = "sha256-IdXv0MfRG1/1pAAwHLS2+1NESFEz2uXrbSdvU9OvdJ8=";
        }
      )
    );
  # nixpkgs discord bundles discord_krisp in the store, and krisp refuses to
  # load ("Application not signed by Discord", error -3) in the patchelf'd
  # binary, so patch the module at build time (a runtime patch cannot touch
  # the read-only store copy).
  # Krisp's engine also needs its module dir WRITABLE at runtime
  # (it creates KMS/logs inside; otherwise init fails with error -4), so
  # override stageModules (nixpkgs #538735) to rsync real copies instead of
  # symlinking store paths. Recipe from NixOS/nixpkgs#195512#issuecomment.
  discord-with-krisp = pkgs.discord.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [krisp-patcher];
    postInstall =
      (old.postInstall or "")
      + ''
        krisp="$out/opt/Discord/modules/discord_krisp/discord_krisp.node"
        if [ -f "$krisp" ]; then
          chmod +w "$krisp"
          ${krisp-patcher}/bin/krisp-patcher "$krisp"
        fi
      '';
    stageModules = pkgs.writeShellScript "discord-stage-writable-modules" ''
      store_modules="$1"
      modules_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/discord/${old.version}/modules"

      mkdir -p "$modules_dir"
      for m in "$store_modules"/*; do
        dest="$modules_dir/$(basename "$m")"

        if [ -L "$dest" ]; then
          rm "$dest"
        fi

        ${lib.getExe' pkgs.rsync "rsync"} -a --checksum --delete "$m/" "$dest"
      done

      chmod -R u+w "$modules_dir"

      echo '${
        builtins.toJSON (lib.mapAttrs (_: mod: {installedVersion = mod;}) old.passthru.moduleVersions)
      }' \
        > "$modules_dir/installed.json"
    '';
  });
in {
  imports = [
    inputs._1password.hmModules.default
    inputs.zen-browser.homeModules.twilight
    ../editor
    ../helix
  ];

  home.packages = with pkgs;
    [
      obsidian
      fontforge
      discord-with-krisp
      vesktop
      # inputs.sidra.packages."${system}".default
      sone
      whatsapp-electron
      zoom-us
      nautilus
      slack
      pkgs-fresh.teams-for-linux
      # inputs.graphite.packages."${system}".default
      inputs.helium.packages."${system}".default
      inputs.ai-usagebar.packages."${system}".default
      # winboat
      gimp
      # parsec-bin
      ryubing
      vlc
      yaak
      filezilla
    ]
    ++ jetbrainsApps
    # ++ affinityApps
    ++ browsers;

  # needed for vicinae to properly launch x apps in niri
  systemd.user.settings.Manager.DefaultEnvironment = {
    DISPLAY = ":0";
    XAUTHORITY = "$HOME/.Xauthority";
  };

  programs = {
    _1password-shell-plugins.enable = true;
    zsh.enable = true;

    zen-browser = let
    containers = {
      personal = {
        color = "purple";
        icon = "fingerprint";
        id = 1;
      };
      werk = {
        color = "blue";
        icon = "briefcase";
        id = 2;
      };
      skewl = {
        color = "yellow";
        icon = "briefcase";
        id = 3;
      };
    };
    spaces = {
      "personal" = {
        id = "10000000-0000-0000-0000-000000000000";
        icon = "👾";
        container = containers.personal.id;
        position = 1000;
      };
      "werk" = {
        id = "20000000-0000-0000-0000-000000000000";
        icon = "🏢";
        container = containers.werk.id;
        position = 2000;
      };
      "skewl" = {
        id = "30000000-0000-0000-0000-000000000000";
        icon = "🎓";
        container = containers.skewl.id;
        position = 3000;
      };
    };
    pins = {
      # Personal
      "mail" = {
        id = "00000000-1000-0000-0000-000000000000";
        container = containers.personal.id;
        url = "https://mail.proton.me/inbox";
        isEssential = true;
        position = 101;
      };
      "dokploy" = {
        id = "00000000-1000-0000-0000-000000000001";
        container = containers.personal.id;
        url = "https://deploy.0xhckr.dev/";
        isEssential = true;
        position = 102;
      };
      "github (personal)" = {
        id = "00000000-1000-0000-0000-000000000002";
        container = containers.personal.id;
        url = "https://github.com/";
        isEssential = true;
        position = 103;
      };
      "hackr.sh" = {
        id = "00000000-1000-0000-0000-000000000003";
        container = containers.personal.id;
        url = "https://hackr.sh/";
        isEssential = true;
        position = 104;
      };
      "cloudflare" = {
        id = "00000000-1000-0000-0000-000000000004";
        container = containers.personal.id;
        url = "https://dash.cloudflare.com/";
        isEssential = true;
        position = 105;
      };

      # Work
      "github (work)" = {
        id = "00000000-2000-0000-0000-000000000000";
        container = containers.werk.id;
        url = "https://github.com/";
        isEssential = true;
        position = 201;
      };
      "outlook (work)" = {
        id = "00000000-2000-0000-0000-000000000001";
        container = containers.werk.id;
        url = "https://outlook.cloud.microsoft/";
        isEssential = true;
        position = 202;
      };
      "teams" = {
        id = "00000000-2000-0000-0000-000000000002";
        container = containers.werk.id;
        url = "https://teams.cloud.microsoft/";
        isEssential = true;
        position = 203;
      };
      "jira" = {
        id = "00000000-2000-0000-0000-000000000003";
        container = containers.werk.id;
        url = "https://knowhistory.atlassian.net/jira/people/712020%3A201746e7-e3ca-4634-85bc-c7b1c68b2ea7/boards/7";
        isEssential = true;
        position = 204;
      };
      "coolify" = {
        id = "00000000-2000-0000-0000-000000000004";
        container = containers.werk.id;
        url = "https://coolify.hstry.dev/";
        isEssential = true;
        position = 205;
      };
      "coolify-mno-pr" = {
        id = "00000000-2000-0000-0000-000000000005";
        container = containers.werk.id;
        url = "https://mno-coolify.hstry.dev/";
        isEssential = true;
        position = 206;
      };
      "azuredevops" = {
        id = "00000000-2000-0000-0000-000000000006";
        container = containers.werk.id;
        url = "https://portal.azure.com/";
        isEssential = true;
        position = 207;
      };

      # Skewl
      "my-ucalgary" = {
        id = "00000000-3000-0000-0000-000000000000";
        container = containers.skewl.id;
        url = "https://my.ucalgary.ca/";
        isEssential = true;
        position = 301;
      };
      "outlook (school)" = {
        id = "00000000-3000-0000-0000-000000000001";
        container = containers.skewl.id;
        url = "https://outlook.cloud.microsoft/";
        isEssential = true;
        position = 302;
      };
      "d2l" = {
        id = "00000000-3000-0000-0000-000000000002";
        container = containers.skewl.id;
        url = "https://d2l.ucalgary.ca/";
        isEssential = true;
        position = 303;
      };
    };
    keyboardShortcuts = [
      # Change compact mode toggle to Ctrl+Alt+S
      {
        id = "zen-compact-mode-toggle";
        key = "s";
        modifiers = {
          control = true;
        };
      }
    ];
    # Fails activation on schema changes to detect potential regressions
    # Find this in about:config or prefs.js of your profile
    keyboardShortcutsVersion = 20;
  in {
    enable = true;
    policies = {
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      # Let Zen update 1Password without Nix restoring an older database reader.
      ExtensionSettings."{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
        installation_mode = "normal_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
        updates_disabled = false;
      };
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };
    profiles."default" = {
      containersForce = true;
      spacesForce = true;
      pinsForce = true;
      extensions.packages = with addons.firefox-addons; [
        ublock-origin
        darkreader
      ];

      # Dual-polarity Pierre chrome that follows the system color-scheme the
      # noctalia toggle flips (replaces stylix's dark-only userChrome, which is
      # disabled below). theme.*-theme = 2 (system) makes zen's prefers-color
      # -scheme track the toggle so the @media blocks switch live.
      userChrome = builtins.readFile ../../../../cfg/zen/userChrome.css;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.theme.toolbar-theme" = 2;
        "browser.theme.content-theme" = 2;
        "layout.css.prefers-color-scheme.content-override" = 2;
      };

      inherit containers spaces pins keyboardShortcuts keyboardShortcutsVersion;
    };
  };
  };

  # Zen-browser: stylix only emits a single-polarity (dark) userChrome, which
  # breaks under the light toggle. Disable its CSS injection; the dual-polarity
  # userChrome on the profile above handles both light and dark.
  stylix.targets.zen-browser = {
    profileNames = ["default"];
    enableCss = false;
  };
}
