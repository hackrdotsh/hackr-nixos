{
  description = "Nixos config flake";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/snapshot.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Local systems set: default minus x86_64-darwin (dropped by nixpkgs 26.11).
    # Bun2nix-based inputs below follow this so they don't evaluate x86_64-darwin.
    systems = {
      url = "path:./systems";
    };

    nixpkgs-fresh = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-26.05";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    umbriel = {
      url = "github:noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nocapture = {
      url = "github:hackrdotsh/nocapture";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      type = "github";
      owner = "niri-wm";
      repo = "niri";
      ref = "main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowstead = {
      url = "github:Polymath-AS/snowstead";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helix = {
      type = "github";
      owner = "helix-editor";
      repo = "helix";
      ref = "master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hytale = {
      url = "github:JPyke3/hytale-launcher-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      type = "github";
      owner = "ghostty-org";
      repo = "ghostty";
      ref = "main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    _1password = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zed = {
      url = "github:zed-industries/zed";
    };

    jj = {
      url = "github:jj-vcs/jj";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jj-starship = {
      url = "github:dmmulroy/jj-starship";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aarch64-tui = {
      url = "git+https://git.co.codes/hackr/aarch64-tui.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gojo = {
      url = "github:hackrdotsh/gojo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    co = {
      url = "github:codotcodes/co";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      type = "github";
      owner = "hackrdotsh";
      repo = "herdr";
      ref = "focus-on-hover";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ai-usagebar = {
      url = "github:akitaonrails/ai-usagebar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs-fresh";
      inputs.systems.follows = "systems";
      inputs.bun2nix.inputs.systems.follows = "systems";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tuigreet = {
      url = "github:NotAShelf/tuigreet";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      x86_systems = [
        "infernape"
        "snorlax"
        "flareon"
      ];
      aarch64_systems = [ ];
      applesilicon_systems = [
        "metagross"
        "mareep"
      ];
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = nixpkgs.lib.nixosSystem {
            modules = [ ./hosts/${name} ];
            specialArgs =
              let
                username = "hackr";
                fullName = "Mohammad Al-Ahdal";
                email = "hackr@hackr.sh";
              in
              {
                inherit inputs;
                inherit system;
                inherit username;
                inherit fullName;
                inherit email;
                inherit x86_systems;
                inherit aarch64_systems;
                pkgs-fresh = import inputs.nixpkgs-fresh {
                  inherit system;
                  config.allowUnfree = true;
                };
                pkgs-stable = import inputs.nixpkgs-stable {
                  inherit system;
                  config.allowUnfree = true;
                };
              };
          };
        }) x86_systems
      );

      # macOS hosts (nix-darwin). Kept deliberately minimal; see modules/darwin.
      darwinConfigurations = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = inputs.nix-darwin.lib.darwinSystem {
            modules = [ ./hosts/${name} ];
            specialArgs =
              let
                darwinSystem = "aarch64-darwin";
                username = "hackr";
                fullName = "Mohammad Al-Ahdal";
                email = "hackr@hackr.sh";
              in
              {
                inherit inputs;
                inherit username;
                inherit fullName;
                inherit email;
                inherit x86_systems;
                inherit aarch64_systems;
                inherit applesilicon_systems;
                system = darwinSystem;
                pkgs-fresh = import inputs.nixpkgs-fresh {
                  system = darwinSystem;
                  config.allowUnfree = true;
                };
              };
          };
        }) applesilicon_systems
      );

      checks.${system} = {
        statix = pkgs.runCommand "statix-check" { } ''
          src=${pkgs.lib.cleanSource ./.}
          ${pkgs.statix}/bin/statix check -c $src $src
          touch $out
        '';
        snowstead-cache =
          pkgs.runCommand "snowstead-cache-check" { nativeBuildInputs = [ pkgs.nodejs_22 ]; }
            ''
              node --test ${./modules/shared/nix-cache}/queue.test.mjs
              touch $out
            '';
      };
    };
}
