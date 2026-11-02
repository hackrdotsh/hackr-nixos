# LLM coding agents from llm-agents.nix, shared by every NixOS and macOS host.
# Home-manager module; also exposes `opencode2` as a module arg for aliases
# and services.
{
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  agents = inputs.llm-agents.packages.${system};

  # OpenTUI dlopens Wayland for clipboard images; wl-clipboard alone is not enough.
  opencode2 =
    if pkgs.stdenv.hostPlatform.isLinux then
      agents.opencode2.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          wrapProgram "$out/bin/opencode2" \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.wayland ]}
        '';
      })
    else
      agents.opencode2;

  instructions = {
    force = true;
    source = ../../cfg/agents/AGENTS.md;
  };
in
{
  _module.args.opencode2 = opencode2;

  home.packages = [
    agents.claude-code
    agents.crush
    agents.herdr-app
    agents.herdr-core
    opencode2
  ];

  home.file = {
    ".claude/CLAUDE.md" = instructions;
    ".codex/AGENTS.md" = instructions;
    ".config/opencode/AGENTS.md" = instructions;
  };
}
