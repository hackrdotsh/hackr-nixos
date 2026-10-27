{
  pkgs,
  inputs,
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

      def copy-to-cache [path: string = "/run/current-system"] {
        ${snowstead}/bin/snowstead push main --server snowstead --closure $path
        if $env.LAST_EXIT_CODE != 0 {
          error make {msg: "Snowstead upload failed. Check cache-login and retry copy-to-cache with the same path."}
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
        copy-to-cache $path
      }

      def re-switch [] { rebuild-and-cache switch }
      def re-boot [] { rebuild-and-cache boot }
      def re-test [] { rebuild-and-cache test }
    '';
  };
}
