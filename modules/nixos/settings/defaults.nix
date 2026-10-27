{
  pkgs,
  pkgs-stable,
  username,
  ...
}: {
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.networkmanager.enable = true; # enable network manager
  time.timeZone = "America/Edmonton"; # set timezone
  i18n.defaultLocale = "en_CA.UTF-8"; # set locale
  services = {
    xserver = {
      enable = true; # enables x11
      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    fwupd.enable = true; # enable firmware updates
    printing.enable = true; # Enable CUPS to print documents.
  };

  nixpkgs.overlays = [
    (final: prev: {
      openssh = prev.openssh.overrideAttrs (old: {
        patches = (old.patches or []) ++ [../../../patches/openssh.patch];
        doCheck = false;
      });
    })
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-jobs = "auto";
      cores = 0;
      auto-optimise-store = true;
      download-buffer-size = 524288000;
      extra-substituters = [
        "https://hackr.snowstead.com/main"
        "https://zed.cachix.org"
        "https://niri.cachix.org"
        "https://ghostty.cachix.org"
        "https://helix.cachix.org"
      ];
      extra-trusted-public-keys = [
        "snowstead-1-46-2deba651-aedb-4282-8561-687368aa1d2f:lVrVBl3DXDSn9wNozthq0OkBu2KWok88dr6OemJSvfk="
        "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
    };
  };
  # Basic packages used everywhere
  environment.systemPackages =
    (with pkgs-stable; [
      wget
      curl
      jq
      python3
    ])
    ++ [
      pkgs.nodejs
    ];

  users.users.${username}.extraGroups = ["networkmanager" "wheel"];
}
