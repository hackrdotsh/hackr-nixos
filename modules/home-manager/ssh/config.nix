{
  username,
  x86_systems,
  aarch64_systems,
  ...
}:
{
  home.file.".ssh/config" = {
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
        ForwardAgent ~/.1password/agent.sock


      # Forward these machines' 1Password agent into the session so that,
      # when SSH'd in from elsewhere, git auth/signing prompts pop on the
      # machine we're sitting at, not the desktop's unreachable GUI.
      ${builtins.concatStringsSep "\n\n" (
        map (system: ''
          Host ${system}
            HostName ${system}
            User ${username}
            ForwardAgent ~/.1password/agent.sock
        '') (x86_systems ++ aarch64_systems)
      )}

      Host *.vm.blacksmith.sh
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null

      # In a forwarded SSH session, use the forwarded agent ($SSH_AUTH_SOCK)
      # so the 1Password prompt appears on the machine we connected from,
      # instead of this host's local (and headless-to-us) 1Password GUI.
      # Force POSIX sh: Match exec runs under $SHELL, which is nushell here.
      # nushell doesn't expand "$SSH_CONNECTION", so the test would always be
      # true (non-empty literal) and clobber IdentityAgent on local pushes too.
      Match exec "sh -c 'test -n \"$SSH_CONNECTION\"'"
        IdentityAgent $SSH_AUTH_SOCK

      Match exec "sh -c 'test -n \"$REX_SESSION\" && test -S \"$HOME/.ssh/rex-1password-agent.sock\"'"
        IdentityAgent ~/.ssh/rex-1password-agent.sock

      Host *
        IdentityAgent ~/.1password/agent.sock
    '';
    force = true;
  };
}
