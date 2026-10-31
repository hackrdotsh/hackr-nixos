{
  config,
  lib,
  pkgs,
  inputs,
  username,
  system,
  ...
}:
let
  cfg = config.services.snowstead-cache;
  home = config.users.users.${username}.home;
  queue = "/nix/var/nix/gcroots/snowstead-auto";
  snowstead = pkgs.callPackage ./snowstead-package.nix { src = inputs.snowstead; };
  node = lib.getExe pkgs.nodejs_22;
  hook = pkgs.writeShellScript "snowstead-cache-hook" ''
    ${node} ${./queue.mjs} enqueue ${queue} || {
      echo "Snowstead cache: could not queue build outputs; build succeeded." >&2
      exit 0
    }
  '';
  upload = "${node} ${./queue.mjs} upload ${queue} ${lib.getExe snowstead}";
  status = pkgs.writeShellScriptBin "cache-status" ''
    exec ${node} ${./queue.mjs} status ${queue}
  '';
  initializeQueue = ''
    ${pkgs.coreutils}/bin/install -d -m 0700 -o ${lib.escapeShellArg username} ${queue}
  '';
  environment = {
    HOME = home;
    XDG_CONFIG_HOME = "${home}/.config";
  };
in
{
  options.services.snowstead-cache.enable =
    lib.mkEnableOption "automatic Snowstead build uploads"
    // {
      default = true;
    };

  config = lib.mkMerge [
    {
      nix.settings = {
        extra-substituters = [ "https://hackr.snowstead.com/main" ];
        extra-trusted-public-keys = [
          "snowstead-1-46-2deba651-aedb-4282-8561-687368aa1d2f:lVrVBl3DXDSn9wNozthq0OkBu2KWok88dr6OemJSvfk="
        ];
      };
    }
    (lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          nix.settings.post-build-hook = hook;
          environment.systemPackages = [
            snowstead
            status
          ];
        }
        (lib.optionalAttrs (lib.hasSuffix "-linux" system) {
          system.activationScripts.snowstead-cache = {
            deps = [ "users" ];
            text = initializeQueue;
          };
          systemd.services.snowstead-cache = {
            description = "Upload queued Nix builds to Snowstead";
            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            inherit environment;
            serviceConfig = {
              Type = "oneshot";
              User = username;
              ExecStart = upload;
              TimeoutStartSec = "infinity";
            };
          };
          systemd.timers.snowstead-cache = {
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "1m";
              OnUnitInactiveSec = "1m";
            };
          };
        })
        (lib.optionalAttrs (lib.hasSuffix "-darwin" system) {
          system.activationScripts.preActivation.text = initializeQueue + ''
            ${pkgs.coreutils}/bin/touch /var/log/snowstead-cache.log
            ${pkgs.coreutils}/bin/chown ${lib.escapeShellArg username} /var/log/snowstead-cache.log
            ${pkgs.coreutils}/bin/chmod 0600 /var/log/snowstead-cache.log
          '';
          launchd.daemons.snowstead-cache = {
            command = upload;
            serviceConfig = {
              UserName = username;
              EnvironmentVariables = environment;
              RunAtLoad = true;
              StartInterval = 60;
              ProcessType = "Background";
              StandardOutPath = "/var/log/snowstead-cache.log";
              StandardErrorPath = "/var/log/snowstead-cache.log";
            };
          };
        })
      ]
    ))
  ];
}
