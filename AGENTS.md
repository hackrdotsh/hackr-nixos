# NixOS configuration agent instructions

## Overview

This is a personal NixOS flake configuration for a single user (`hackr`, Mohammad Al-Ahdal) across multiple machines. All host configurations share a common module base and are composed via `flake.nix`.

- **Flake inputs** are pinned in `flake.lock`. Always keep `inputs.nixpkgs.follows = "nixpkgs"` when adding new inputs.
- **Special args** passed to every host: `inputs`, `system` (`x86_64-linux`), `username` (`hackr`), `fullName`, `email`.
- **Home Manager** is embedded as a NixOS module (not standalone). The single user's HM config is wired in via `modules/nixos/settings/users.nix` → `modules/home-manager/default.nix` → `modules/home-manager/links.nix`.

---

## Commands

| Purpose | Command |
|---|---|
| Apply config (preferred) | `nh os switch ~/nixos` |
| Apply config (fallback) | `sudo nixos-rebuild switch --flake .#<hostname>` |
| Test without activating | `nh os test ~/nixos` |
| Check flake syntax | `nix flake check` |
| Inspect flake outputs | `nix flake show` |
| Run a flake app | `nr <app-name>` (nushell alias) |
| Rebuild and cache (nushell alias) | `rebuild`; pushes the successful system closure to Snowstead on every NixOS host |

Hosts: `infernape`, `snorlax`, `flareon`

---

## Directory structure

```
flake.nix                        # Entry point; defines all inputs and nixosConfigurations
flake.lock                       # Pinned input revisions; commit after updates
hosts/
  infernape/                     # Primary desktop (state 24.11)
  snorlax/                       # Work laptop, NVIDIA + OpenRazer (state 24.11)
  flareon/                       # Laptop, includes flareon-audio.nix (state 25.05)
    default.nix                  # Imports common modules + host-specific hardware
    boot.nix                     # Bootloader / kernel configuration
    hardware-configuration.nix   # Generated. Do NOT hand-edit
modules/
  nixos/                         # System-level (runs as root / NixOS options)
    apps/                        # System-installed apps
      dev/                       # agents.nix, nushell (system-level)
      games/                     # steam, gamescope, prism, hytale, smm, gs.sh helper
      1password-browsers.nix
      libre-office.nix
      netbird.nix / tailscale.nix
      obs.nix / ollama.nix
    hardware/
      snorlax-nvidia.nix
      snorlax-openrazer.nix
      snorlax-power-management.nix
      flareon-audio.nix
    security/
      1password.nix              # polkit owner = username
      fingerprint.nix / pam.nix / polkit.nix
    settings/
      defaults.nix / firewall.nix / sound.nix / ssh.nix
      users.nix                  # Defines user, sets shell=nushell, imports HM
    styles/
      fonts.nix
      stylix.nix                 # Stylix enabled; base16 = rose-pine, cursor = BreezeX-RosePine-Linux
      themes/                    # rose-pine.yaml, poimandres.yaml, oscura-midnight.yaml
    system/
      gnome.nix / keyd.nix
      nh.nix                     # nh flake = ~/nixos, auto-clean keep 3d/3 gens
      niri.nix                   # Enables niri (niri-unstable flake input), xwayland-satellite
    virtualization/
      distrobox.nix / flatpak.nix
  home-manager/                  # User-level (runs as hackr / HM options)
    links.nix                    # Root HM file: imports all sub-modules, declares home.file symlinks & activations
    apps/
      general/default.nix        # JetBrains IDEs, Affinity v3, zen-browser (twilight),
                                 # discord, obsidian, zoom, slack, GIMP, VLC, Yaak, etc.
                                 # discord is wrapped (discord-with-krisp): krisp-patcher
                                 # patches discord_krisp.node at BUILD time (postInstall).
                                 # nixpkgs discord bundles krisp in the store (read-only), so
                                 # runtime patching from startup scripts does NOT work. Its
                                 # stageModules is also overridden to rsync WRITABLE module
                                 # copies at launch (krisp creates KMS/logs in its dir; with
                                 # store symlinks the init fails with error -4).
      editor/                    # Zed (built from flake w/ FHS env), language servers, settings.json
      helix/                     # Helix (from helix flake master)
    dev/default.nix              # git, direnv, android-tools, nil, nixfmt, gcc, cargo, nodejs, bun, jdk, mc
    shell/
      atuin.nix / carapace.nix / starship.nix / zoxide.nix
      nushell.nix                # Main shell; defines nr, code, zc, zic, pokefetch
      nix-cache.nix              # Snowstead login/upload helpers and rebuild wrappers
    ssh/
      1password-agent.nix / config.nix / keys.nix
      git.nix                    # Drops ~/.gitconfig, ~/work/.gitconfig, ~/dev/.gitconfig
    terminal/
      ghostty.nix                # Ghostty config (DepartureMono Nerd Font, rose-pine theme, keybinds)
    ui/
      niri.nix                   # Writes ~/.config/niri/config-original.kdl (KDL, host-aware outputs)
      umbriel.nix                # Writes ~/.config/umbriel/config-settings.toml, validates and copies
                                 # it to writable config.toml on activation; host-aware outputs
      noctalia.nix               # Noctalia v5 config (attrset -> TOML config.toml, build-validated);
                                 # plugins are Luau (<author>/<plugin>), palette via customPalettes
    work/
      azure.nix
  shared/
    nix-cache/                   # Snowstead CLI, nonblocking build hook, queue, OS upload services
cfg/                             # Static config files symlinked into ~/.config/ via links.nix
  atuin/ btop/ direnv/ fastfetch/
  niri/                          # delayed (startup script), laptop-outputs.kdl (snorlax/flareon)
  noctalia/                      # palettes/Pierre.json (v5 palette layout, flat)
  nushell/                       # direnv.nu, aacpi.sh
  vicinae/scripts/               # Scripts for vicinae launcher
  zed/                           # themes/, keymap.json
share/
  vicinae/themes/                # Vicinae theme files → ~/.local/share/vicinae/themes
ssh/                             # authorized_keys, home.gitconfig, work.gitconfig, dev.gitconfig
patches/                         # Ad-hoc nixpkgs patches
```

---

## Code style

- **Indentation.** 2 spaces, no tabs.
- **Nix formatting.** `nixfmt` is approved for this repository; use the existing Nix toolchain if it is not on `PATH`.
- **Package references.** `pkgs.<name>` or `lib.getExe pkgs.<name>` for shell scripts.
- **String interpolation.** `${pkgs.foo}/bin/foo`; always interpolate store paths.
- **Overrides.** Use `lib.mkForce` when overriding values inherited from other modules.
- **Module focus.** Each `.nix` file should configure one concern. Group related files under a subdirectory with a `default.nix` that only contains `imports = [ ... ]`.
- **Static configs.** Put non-Nix config files (KDL, JSON, shell scripts) in `cfg/` and symlink them via `links.nix` `home.file` entries with `force = true`.
- **Generated files.** `hardware-configuration.nix` is generated; never edit by hand.
- **`allowUnfree`.** Set in `links.nix` (`nixpkgs.config.allowUnfree = true`); no need to repeat elsewhere.

---

## Key patterns

### Adding a new NixOS module
1. Create `modules/nixos/<category>/<name>.nix`.
2. Add it to the relevant `modules/nixos/<category>/default.nix` imports list.
3. It will be picked up automatically by all hosts via `modules/nixos/default.nix`.

### Adding a host-specific NixOS module
Import it directly in `hosts/<hostname>/default.nix`:
```nix
imports = [
  ../../modules/nixos
  ../../modules/nixos/hardware/my-hardware.nix
  ./hardware-configuration.nix
  ./boot.nix
];
```

### Adding a new Home Manager module
1. Create `modules/home-manager/<category>/<name>.nix`.
2. Add it to the relevant `modules/home-manager/<category>/default.nix` imports list.
3. It is picked up via `links.nix` → category `default.nix`.

### Adding static config files
1. Drop the file in `cfg/<app>/`.
2. Add a `home.file` entry in `links.nix`:
```nix
".config/<app>" = {
  force = true;
  source = ../../cfg/<app>;
  recursive = true;
};
```

### Activation scripts (post-generation fixups)
Add to `home.activation` in `links.nix` or the relevant HM module:
```nix
home.activation.myFixup = lib.hm.dag.entryAfter ["linkGeneration"] ''
  #!/usr/bin/env bash
  cp -L ~/.config/app/template.json ~/.config/app/live.json
'';
```
This pattern is used for niri (`config-original.kdl` → `config.kdl`), Umbriel (`config-settings.toml` → `config.toml`), and zed settings so that the live files are mutable at runtime while the source remains managed by Nix. Umbriel's activation validates the template and installs the live file with mode `0644`; local edits survive until the next activation, which restores the Nix baseline. Noctalia v5 no longer needs it (GUI writes to `~/.local/state/noctalia/settings.toml`, which layers over the Nix `config.toml`).

### Theming
- Stylix drives the system-wide base16 theme (`rose-pine`). To opt a target out: `stylix.targets.<name>.enable = false;` (see `editor/default.nix` for Zed).
- Themes live in `modules/nixos/styles/themes/`. To switch themes, update the `base16Scheme` path in `modules/nixos/styles/stylix.nix`.

### Accessing flake inputs inside modules
All inputs are forwarded via `specialArgs`. Destructure in the function head:
```nix
{ inputs, system, pkgs, ... }: {
  environment.systemPackages = [ inputs.some-flake.packages.${system}.default ];
}
```

### Host-conditional logic (inside HM modules)
The `hostname` special arg is derived from `config.networking.hostName` and passed through HM's `extraSpecialArgs`:
```nix
{ hostname, ... }:
  lib.optionalString (hostname == "snorlax" || hostname == "flareon") "...";
```
See `modules/home-manager/ui/niri.nix` for a real example (laptop output block).

---

## Flake inputs of note

| Input | Purpose |
|---|---|
| `nixpkgs` | `nixos-unstable`, the primary package set |
| `nixpkgs-stable` | `nixos-25.11`, available for stable pin-outs |
| `home-manager` | Follows nixpkgs |
| `stylix` | System-wide theming via base16 |
| `niri-unstable` | WIP niri branch (used as the actual niri package) |
| `helix` | Helix editor from `master` |
| `zed` | Zed editor from source |
| `ghostty` | Ghostty terminal from `main` |
| `zen-browser` | Zen Browser (twilight channel) |
| `noctalia` | Noctalia shell/bar (**v5**, C++ rewrite; repo renamed noctalia-shell → noctalia; v4 = `legacy-v4` branch) |
| `vicinae` | Vicinae app launcher |
| `awww` | Wallpaper daemon (`awww-daemon`) |
| `affinity-nix` | Affinity suite on Linux |
| `_1password` | 1Password shell plugins |
| `nh` | `nh` NixOS helper |
| `snowstead` | CLI for uploading closures to the shared Snowstead cache |
| `nix-vscode-extensions` | VS Code extension set |
| `hytale` | Hytale launcher |
| `graphite` | Graphite editor |

---

## Nushell aliases & functions (defined in `modules/home-manager/shell/`)

| Name | Description |
|---|---|
| `rebuild` / `re-switch` | `nh os switch ~/nixos`, then upload the active system closure to Snowstead |
| `re-boot` / `re-test` | Rebuild for boot/test, then upload the selected system closure |
| `nr <name>` | Run a flake app (`nix run .#<name>`); `nr list` lists available apps |
| `code [path]` | Open Zed (nohup, detached) |
| `zc [path]` | `zoxide` jump + open Zed |
| `zic [path]` | `zoxide` interactive jump + open Zed |
| `pokefetch` | Fastfetch with a pokémon sprite (hostname as pokémon name) |
| `cache-login` | Prompt for a Snowstead push token and save a local CLI login |
| `cache-status` | List build outputs queued for automatic Snowstead upload on either OS |
| `copy-to-cache [path]` | Upload a closure to Snowstead; defaults to `/run/current-system` |
| `point-and-kill` | Pick a niri window and `kill -9` its PID |
| `cl` | Clear screen + run `pokefetch` (if not in tmux) |
| `g` / `gc` / `gp` / `gl` / `gco` | Git shortcuts |
| `b` | `bun` |
| `c` | `code` |
| `oc` | `opencode` |

---

## Nix binary cache

All NixOS and nix-darwin hosts read from `https://hackr.snowstead.com/main`, alongside upstream
caches. Snowstead replaces the old S3 cache and signs uploads server-side; the
old `~/.config/nix/secret.key` and `nixbuilder` AWS profile are no longer used by
these helpers.

After applying this configuration, open a new Nushell and run `cache-login` on
each uploading machine with a push token scoped to `hackr`'s `main` cache. The CLI
stores it in `~/.config/snowstead/config.json`, outside the repository and Nix
store. Do not put tokens in Nix files or shell command history.

Every configured NixOS and nix-darwin host automatically queues newly built Nix
outputs for upload. The post-build hook only creates local GC-root symlinks under
`/nix/var/nix/gcroots/snowstead-auto`; it never contacts Snowstead or fails a build.
The queue survives reboots and protects pending outputs from garbage collection.
An uploader runs as `hackr`, using the login above, once per minute while idle.
It uploads each output's closure and removes its queue root only after success.
Network, authentication, or upload failures retain the pending roots for retry.
The OS service manager prevents overlapping uploader runs.

Run `cache-status` to inspect the queue. On NixOS, inspect logs with
`journalctl -u snowstead-cache` and retry now with
`sudo systemctl start snowstead-cache`. On macOS, logs are in
`/var/log/snowstead-cache.log`; retry with
`sudo launchctl kickstart system/org.nixos.snowstead-cache`.
Disable automatic uploads declaratively with
`services.snowstead-cache.enable = false;`. Disabling does not delete pending
roots; remove unwanted symlinks from the queue explicitly to release them.

Automatic uploads cover actual Nix builds, not previously existing outputs,
substituted paths on their own, or plain `cargo`/`bun` builds outside Nix. Private
project outputs and source-containing store paths can be uploaded too; confirm
the destination cache's read access before building sensitive projects. Platforms
share one cache, but only identical store paths are reusable across machines.

`rebuild`, `re-switch`, `re-boot`, and `re-test` upload only after a successful
rebuild. These NixOS wrappers still upload synchronously in addition to automatic
build-output uploads; direct Nix commands only use the automatic queue. Use
`copy-to-cache ./result` for other build outputs, or `copy-to-cache` to upload the
current system without rebuilding it. On `infernape`, bare `copy-to-cache` and
the rebuild wrappers also discover other NixOS hosts in `~/nixos` with the same
Nix platform, build their system closures, and upload them sequentially. Explicit
`copy-to-cache <path>` uploads only that path. Other hosts still upload only their
own closure. Peer builds are not activated; their GC roots live in
`${XDG_STATE_HOME:-~/.local/state}/nixos/cache-builds/<host>` and can be removed
when those retained builds are no longer needed. All machines must use the same
configuration and lockfile to reuse the cached outputs.

Upload and peer-build failures are reported separately;
they do not undo a successful activation. For `re-boot`, the uploaded root is
`/nix/var/nix/profiles/system`, not the old running system.

---

## Machines

### `infernape`
- **Hardware.** Desktop PC
- Primary workstation (`stateVersion = "24.11"`)
- Imports base `modules/nixos` only (no extra hardware modules)
- Uses the shared Snowstead rebuild/upload workflow, like the other NixOS hosts

### `flareon`
- **Hardware.** Framework 13 Pro
- (`stateVersion = "25.05"`)
- Extra import: `modules/nixos/hardware/flareon-audio.nix` (Framework-specific audio quirks)
- Niri config includes laptop output block from `cfg/niri/laptop-outputs.kdl`

### `snorlax`
- **Hardware.** Razer Blade 17
- (`stateVersion = "24.11"`)
- Extra imports: `snorlax-nvidia.nix`, `snorlax-openrazer.nix`, `snorlax-power-management.nix`
- User added to `openrazer` group (Razer peripheral support)
- Niri config includes laptop output block (same KDL as flareon)
