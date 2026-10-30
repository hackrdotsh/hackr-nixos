{
  pkgs,
  inputs,
  lib,
  hostname,
  ...
}:
let
  snowstead = pkgs.callPackage ./snowstead-package.nix { src = inputs.snowstead; };
in
{
  home.packages = [ snowstead ];

  programs.nushell = {
    shellAliases.rebuild = "re-switch";
    extraConfig = ''
      def cache-login [] {
        let token = (input --suppress-output "Snowstead push token: ")
        if ($token | is-empty) {
          error make {msg: "A Snowstead push token is required."}
        }
        ${snowstead}/bin/snowstead login snowstead https://cache.snowstead.com $token
        if $env.LAST_EXIT_CODE != 0 {
          error make {msg: "Snowstead login failed."}
        }
      }

      def upload-cache-closure [path: string] {
        ${snowstead}/bin/snowstead push main --server snowstead --closure $path
        if $env.LAST_EXIT_CODE != 0 {
          error make {msg: "Snowstead upload failed. Check cache-login and retry copy-to-cache with the same path."}
        }
      }

      def cache-system-closures [path: string] {
        upload-cache-closure $path
        ${lib.optionalString (hostname == "infernape") ''
          let flake = ($env.HOME | path join "nixos")
          let result = (${pkgs.nix}/bin/nix eval --json --no-write-lock-file $"($flake)#nixosConfigurations" --apply 'configs: builtins.filter (name: (builtins.getAttr name configs).pkgs.stdenv.hostPlatform.system == "${pkgs.stdenv.hostPlatform.system}") (builtins.attrNames configs)' | complete)
          if $result.exit_code != 0 {
            error make {msg: $"Local system uploaded, but discovering other hosts failed: ($result.stderr)"}
          }
          let hosts = ($result.stdout | from json | where {|name| $name != "${hostname}" })
          let state = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
          let roots = ($state | path join "nixos" "cache-builds")
          mkdir $roots
          for host in $hosts {
            print $"Building ($host) for the cache..."
            let root = ($roots | path join $host)
            ${pkgs.nix}/bin/nix build --no-write-lock-file --out-link $root $"($flake)#nixosConfigurations.($host).config.system.build.toplevel"
            if $env.LAST_EXIT_CODE != 0 {
              error make {msg: $"Local system uploaded, but building ($host) failed. Retry copy-to-cache after fixing the build."}
            }
            upload-cache-closure $root
          }
        ''}
      }

      def copy-to-cache [path?: string] {
        if $path == null {
          cache-system-closures /run/current-system
        } else {
          upload-cache-closure $path
        }
      }

      def rebuild-and-cache [action: string] {
        ${pkgs.nh}/bin/nh os $action ~/nixos
        if $env.LAST_EXIT_CODE != 0 {
          error make {msg: "NixOS rebuild failed; nothing was uploaded."}
        }
        # A boot rebuild changes the system profile, not the running system.
        let path = if $action == "boot" {
          "/nix/var/nix/profiles/system"
        } else {
          "/run/current-system"
        }
        cache-system-closures $path
      }

      def re-switch [] { rebuild-and-cache switch }
      def re-boot [] { rebuild-and-cache boot }
      def re-test [] { rebuild-and-cache test }
    '';
  };
}
