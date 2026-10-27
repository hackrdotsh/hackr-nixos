{
  pkgs,
  config,
  lib,
  inputs,
  system,
  username,
  opencode2,
  ...
}: {
  home.shell.enableNushellIntegration = true;

  programs.nushell = {
    enable = true;
    environmentVariables = config.home.sessionVariables;
    extraConfig = ''
      use std "path add"

      path add "/run/current-system/sw/bin"
      path add "~/bin"
      path add "~/.local/bin"
      path add "~/.nix-profile/bin"
      path add "~/.bun/bin"
      path add "/run/wrappers/bin"
      path add "/var/lib/flatpak/exports/share"
      path add "/home/${username}/.local/share/flatpak/exports/share"

      source ./direnv.nu


      def cl [] {
        clear
        if $env.TMUX? == null {
          pokefetch
        }
      }

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

      # Expand a leading `~` (string args skip nushell's tilde expansion) and pass
      # args to bash positionally so paths with spaces survive.
      def code [...args: string] {
        let args = $args | each {|arg| if ($arg | str starts-with "~") { $arg | path expand } else { $arg } }
        bash -c 'TERM=xterm-256color nohup "$0" "$@" >/dev/null 2>&1 &' ${config.home.zedPackage}/bin/zed ...$args
      }

      # Enable zoxide integration
      source ${
        pkgs.runCommand "zoxide-nushell-config.nu" {} ''
          ${lib.getExe pkgs.zoxide} init nushell >> "$out"
        ''
      }

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

      def point-and-kill [] {
        let appPID = ${pkgs.niri}/bin/niri msg pick-window | grep "PID:" | str replace "PID: " "" | into int
        kill -9 $appPID
      }

      def ghosttify [user: string, host: string] {
        let command = ["infocmp -x xterm-ghostty | ssh ", $user, "@", $host, " -- tic -x -"]
        bash -c ($command | str join)
      }

      def pokefetch [] {
        let FETCHER_CMD = "${pkgs.fastfetch}/bin/fastfetch --logo none"
        let EXTRA_PADDING_H = 2
        let EXTRA_PADDING_W = 2
        let WIDTH = 38

        # Get hostname and use it as the Pokemon name
        let pokemon_name = (hostname)

        # Get the sprite
        let sprite = (${pkgs.pokeget-rs}/bin/pokeget $pokemon_name --hide-name --shiny | complete | get stdout)

        # Get fetcher height
        let fetcher_height = (bash -c $FETCHER_CMD | lines | length)

        # Get sprite height
        let sprite_height = ($sprite | lines | length)

        # Calculate vertical padding
        let pad_top = (($fetcher_height - $sprite_height) / 2 + $EXTRA_PADDING_H)
        let pad_top = (if $pad_top < 0 { 0 } else { $pad_top })

        # Get sprite width (strip ANSI codes and find max width)
        let sprite_width = ($sprite | lines | each { |line|
          $line | ansi strip | split chars | length
        } | math max)

        # Calculate horizontal padding
        let pad_horizontal = (($WIDTH - $sprite_width) / 2 + $EXTRA_PADDING_W)
        let pad_horizontal = (if $pad_horizontal < 1 { 1 } else { $pad_horizontal })
        let pad_horizontal = ($pad_horizontal | math floor)
        let pad_top = ($pad_top | math floor)

        # Run fastfetch with the sprite
        $sprite | ${pkgs.fastfetch}/bin/fastfetch --file-raw - --logo-padding $pad_horizontal --logo-padding-top $pad_top
      }

      ~/.config/nushell/aacpi.sh

      # check if running as xterm-ghostty and not launched from pi hackr-ui cmd mode
      if $env.TERM == "xterm-ghostty" and ($env.HACKR_UI_CMD? | is-empty) {
        pokefetch
      }
    '';

    shellAliases = {
      pip = "${pkgs.python3}/bin/python3 -m pip";
      g = "${pkgs.git}/bin/git";
      gc = "${pkgs.git}/bin/git commit -m";
      gp = "${pkgs.git}/bin/git push";
      gl = "${pkgs.git}/bin/git pull";
      gco = "${pkgs.git}/bin/git checkout";
      l = "ls -la";
      b = "${pkgs.bun}/bin/bun";
      c = "code";
      oc = "${opencode2}/bin/opencode2";
    };
  };

  home.file = {
    ".config/nushell/direnv.nu" = {
      source = ../../../cfg/nushell/direnv.nu;
    };
    ".config/nushell/aacpi.sh" = {
      source = ../../../cfg/nushell/aacpi.sh;
    };
  };
}
