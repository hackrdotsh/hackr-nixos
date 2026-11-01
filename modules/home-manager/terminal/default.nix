{
  pkgs,
  inputs,
  system,
  ...
}:
{
  imports = [
    ./ghostty.nix
  ];

  home.packages = with pkgs; [
    (btop.override {
      rocmSupport = true;
    })
    atuin
    lazygit
    pokeget-rs
    fastfetch
    fzf
    ripgrep
    bat
    gh
    nix-output-monitor
    libnotify
    psmisc
    inputs.ghostty.packages."${system}".default
  ];

  home.file = {
    ".config/nushell/env.nu" = {
      force = true;
      text = ''
        $env.config.show_banner = false
        $env.DIRENV_LOG_FORMAT = ""
        $env.NIXPKGS_ALLOW_UNFREE = "1"
        if ($env.REX_SESSION? != null) {
          $env.SSH_AUTH_SOCK = $"($env.HOME)/.ssh/rex-1password-agent.sock"
        }
      '';
    };
  };
}
