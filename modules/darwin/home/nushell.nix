# Nushell config. Nushell itself comes from Homebrew (see ../homebrew.nix);
# here we only manage its config files. On macOS nushell reads its config from
# ~/Library/Application Support/nushell, not ~/.config/nushell.
{
  username,
  pkgs,
  inputs,
  ...
}:
let
  configDir = "Library/Application Support/nushell";
  snowstead = pkgs.callPackage ../../shared/nix-cache/snowstead-package.nix {
    src = inputs.snowstead;
  };
in
{
  home.file = {
    # Shared, cross-platform direnv hook (also used by the NixOS config).
    "${configDir}/direnv.nu".source = ../../../cfg/nushell/direnv.nu;

    "${configDir}/env.nu".text = ''
      # Make bare `nh darwin switch` target this flake.
      $env.NH_FLAKE = "/Users/${username}/nixos"
    '';

    "${configDir}/config.nu".text = ''
      use std "path add"

      path add "/opt/homebrew/bin"
      path add "/run/current-system/sw/bin"
      path add "/etc/profiles/per-user/${username}/bin"
      path add "~/.nix-profile/bin"
      path add "~/.local/bin"
      path add "~/bin"

      # direnv hook
      source ./direnv.nu

      # starship prompt (init rendered at build time; see starship.nix)
      source ./starship-init.nu

      # zoxide (init rendered at build time; see zoxide.nix). Sourced before the
      # zc/zic helpers below so __zoxide_z/__zoxide_zi are defined.
      source ./zoxide-init.nu

      # Rebuild helpers, mirroring the NixOS aliases. `nh darwin` only has
      # switch/build (macOS has no bootloader generations), so re-test maps to
      # a non-activating build and re-boot maps to switch.
      def re-switch [] { nh darwin switch ~/nixos }
      def re-test [] { nh darwin build ~/nixos }
      def re-boot [] { nh darwin switch ~/nixos }

      ${import ../../shared/nix-cache/login.nix { inherit snowstead; }}

      # Launch Zed. The `zed` CLI is on PATH via the Homebrew cask.
      # Expands a leading `~`, which string args skip in nushell.
      def --wrapped code [...args: string] {
        zed ...($args | each {|arg| if ($arg | str starts-with "~") { $arg | path expand } else { $arg } })
      }

      # zoxide + Zed combos (mirrors the NixOS helpers).
      def --env --wrapped zc [...args: string] {
        if $args == null or $args == [] {
          cd ~
          code
        } else {
          __zoxide_z ...$args
          code .
        }
      }

      def --env --wrapped zic [...args: string] {
        if $args == null or $args == [] {
          __zoxide_zi
          code .
        } else {
          __zoxide_zi ...$args
          code .
        }
      }

      # `nr [app] [args]` runs a flake app from the current dir (defaults to
      # `.#default`); `nr list` lists the apps available for this system.
      def nr [
        name: string = "default",
        ...rest: string
      ] {
        if $name == "list" {
          nix flake show --json --all-systems | from json | get apps | get (nix eval --impure --expr 'builtins.currentSystem' --raw) | transpose | get column0
        } else {
          let flake_ref = [".#", $name] | str join ""
          ^nix run $flake_ref ...$rest
        }
      }

      # fastfetch (Homebrew) + pokeget-rs (nix) side by side, sprite picked
      # from the hostname, so `metagross` renders the Metagross sprite.
      def pokefetch [] {
        let FETCHER_CMD = "fastfetch --logo none"
        let EXTRA_PADDING_H = 2
        let EXTRA_PADDING_W = 2
        let WIDTH = 38

        # Strip any domain suffix (e.g. metagross.local -> metagross).
        let pokemon_name = (hostname | split row "." | first)

        let sprite = (pokeget $pokemon_name --hide-name --shiny | complete | get stdout)

        let fetcher_height = (bash -c $FETCHER_CMD | lines | length)
        let sprite_height = ($sprite | lines | length)

        let pad_top = (($fetcher_height - $sprite_height) / 2 + $EXTRA_PADDING_H)
        let pad_top = (if $pad_top < 0 { 0 } else { $pad_top })

        let sprite_width = ($sprite | lines | each { |line|
          $line | ansi strip | split chars | length
        } | math max)

        let pad_horizontal = (($WIDTH - $sprite_width) / 2 + $EXTRA_PADDING_W)
        let pad_horizontal = (if $pad_horizontal < 1 { 1 } else { $pad_horizontal })
        let pad_horizontal = ($pad_horizontal | math floor)
        let pad_top = ($pad_top | math floor)

        $sprite | fastfetch --file-raw - --logo-padding $pad_horizontal --logo-padding-top $pad_top
      }

      def cl [] {
        clear
        if $env.TMUX? == null {
          pokefetch
        }
      }

      # Aliases (ported from the NixOS shell config). `c` resolves to the `code`
      # def above. `b` expects bun, which isn't installed yet.
      alias pip = python3 -m pip
      alias g = git
      alias gc = git commit -m
      alias gp = git push
      alias gl = git pull
      alias gco = git checkout
      alias l = ls -la
      alias b = bun
      alias c = code
      alias oc = opencode2

      $env.config.show_banner = false

      # Greet on interactive ghostty sessions, like the NixOS config.
      if $env.TERM == "xterm-ghostty" {
        pokefetch
      }
    '';
  };
}
