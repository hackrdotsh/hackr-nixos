{
  pkgs-stable,
  lib,
  inputs,
  system,
  ...
}: {
  # Enable Niri
  programs.niri = {
    enable = true;
    # package = pkgs.niri;
    # Upstream's flake package installs its systemd units into
    # share/systemd/user, but nixpkgs' programs.niri now relies on
    # systemd.packages, which only scans lib/systemd/user. Without the
    # units there, niri.service is generated with no ExecStart and the
    # session fails to start. Install them where NixOS looks, like the
    # nixpkgs niri package does.
    package = inputs.niri.packages.${system}.niri.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          install -Dm644 resources/niri{.service,-shutdown.target} -t $out/lib/systemd/user
        '';
    });
  };

  environment.systemPackages = with pkgs-stable; [
    xwayland-satellite
  ];

  # services.displayManager.defaultSession = lib.mkForce "niri";
}
