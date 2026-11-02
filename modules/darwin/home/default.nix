# Home-manager config for the macOS user. This is where dotfiles are managed.
{
  username,
  lib,
  pkgs,
  pkgs-fresh,
  inputs,
  system,
  ...
}:
{
  imports = [
    ./nushell.nix
    ./starship.nix
    ./zoxide.nix
    ../../shared/agents.nix
    ./claude.nix
    ./docker.nix
    ./fastfetch.nix
    ./ghostty.nix
    ./gojo.nix
    ./git.nix
    ./jj.nix
    ./obsidian.nix
    ./ssh.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "26.11";
    packages = [
      pkgs.awscli2
      pkgs.gh
      pkgs-fresh.secretspec
      inputs.co.packages.${system}.default
    ];
  };

  programs.home-manager.enable = true;

  # nix-darwin manages /etc/zshrc; let home-manager own the user's zsh so the
  # direnv hook below actually gets sourced.
  programs.zsh.enable = true;

  # Install direnv + nix-direnv and register the shell hook.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    # Suppress the noisy `direnv: export +AR +AS +CC ...` diff on every load.
    # Mirrors cfg/direnv/direnv.toml, which the Linux config links directly
    # (can't symlink the dir here since nix-direnv owns ~/.config/direnv/lib).
    config.global = {
      hide_env_diff = true;
      log_format = "";
    };
  };
}
