# SSH client config + 1Password SSH agent.
{
  username,
  hostname,
  lib,
  pkgs,
  x86_systems,
  aarch64_systems,
  ...
}:
let
  # macOS 1Password SSH agent socket (differs from the Linux ~/.1password path).
  agentSock = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
in
{
  # Rex doesn't forward agents. Keep a separate SSH tunnel to each Linux host.
  launchd.agents = lib.mkIf (hostname == "metagross") (
    builtins.listToAttrs (
      map (host: {
        name = "rex-1password-agent-${host}";
        value = {
          enable = true;
          config = {
            ProgramArguments = [
              "${pkgs.openssh}/bin/ssh"
              "-N"
              "-T"
              "-o"
              "BatchMode=yes"
              "-o"
              "ForwardAgent=no"
              "-o"
              "ExitOnForwardFailure=yes"
              "-o"
              "ServerAliveInterval=30"
              "-o"
              "ServerAliveCountMax=3"
              "-R"
              "/home/${username}/.ssh/rex-1password-agent.sock:/Users/${username}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
              host
            ];
            RunAtLoad = true;
            KeepAlive.SuccessfulExit = false;
            ThrottleInterval = 30;
          };
        };
      }) (x86_systems ++ aarch64_systems)
    )
  );

  home.file = {
    ".ssh/config" = {
      force = true;
      text = ''
        Host thundurus
          HostName 54.39.157.27
          User ${username}
          Port 22222

        Host 10.0.11.5
          HostName 10.0.11.5
          User ${username}

        Host mareep
          HostName mareep
          User ${username}
          ForwardAgent "${agentSock}"

        # Forward this Mac's 1Password agent into these sessions so that git
        # auth/signing prompts pop here, on the machine we're sitting at.
        ${builtins.concatStringsSep "\n\n" (
          map (host: ''
            Host ${host}
              HostName ${host}
              User ${username}
              ForwardAgent "${agentSock}"
          '') (x86_systems ++ aarch64_systems)
        )}

        Host *.vm.blacksmith.sh
          StrictHostKeyChecking no
          UserKnownHostsFile /dev/null

        # In a forwarded SSH session, use the forwarded agent ($SSH_AUTH_SOCK)
        # so the 1Password prompt appears on the machine we connected from.
        # Force POSIX sh for the test (the login shell may be nushell).
        Match exec "sh -c 'test -n \"$SSH_CONNECTION\"'"
          IdentityAgent $SSH_AUTH_SOCK

        Host *
          IdentityAgent "${agentSock}"
      '';
    };

    ".ssh/hackr-general.pub" = {
      source = ../../../ssh/hackr-general.pub;
      force = true;
    };

    # Which key the 1Password SSH agent offers.
    ".config/1Password/ssh/agent.toml" = {
      force = true;
      text = ''
        [[ssh-keys]]
        vault = "Private"
        item = "hackr-general"
      '';
    };
  };
}
