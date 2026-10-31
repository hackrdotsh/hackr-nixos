# Shared nix-darwin base. Mirrors modules/nixos but for macOS hosts.
# Kept small on purpose. Most user-facing config lives in home-manager.
{
  inputs,
  system,
  username,
  fullName,
  email,
  x86_systems,
  aarch64_systems,
  pkgs-fresh,
  config,
  ...
}:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ./homebrew.nix
    ../shared/nix-cache
  ];

  nixpkgs.hostPlatform = system;
  nixpkgs.config.allowUnfree = true;

  # Enable flakes + the new CLI for `darwin-rebuild --flake`.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Required by nix-darwin whenever user-scoped options (incl. home-manager)
  # are in play, so it knows which user to apply them for.
  system.primaryUser = username;

  # References the existing macOS account; nix-darwin won't create it.
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Manage the login shell's /etc/zshrc so nix + the direnv hook load.
  programs.zsh.enable = true;

  # nh isn't in Homebrew, so install it from nix. NH_FLAKE makes bare
  # `nh darwin switch` target this flake (see the re-switch helper in nushell).
  environment.systemPackages = [
    inputs.nh.packages.${system}.default
  ];
  environment.variables.NH_FLAKE = "/Users/${username}/nixos";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
    extraSpecialArgs = {
      inherit
        inputs
        system
        username
        fullName
        email
        ;
      inherit x86_systems aarch64_systems pkgs-fresh;
      hostname = config.networking.hostName;
    };
    users.${username} = import ./home;
  };
}
