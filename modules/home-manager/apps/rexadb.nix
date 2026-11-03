{ inputs, pkgs, ... }:
{
  home.packages = [
    (inputs.rexadb.packages.${pkgs.stdenv.hostPlatform.system}.rexadb.overrideAttrs (old: {
      # Diagnostics already default off; keep update requests opt-in too.
      postPatch = (old.postPatch or "") + ''
        substituteInPlace lib/privacy-settings.ts \
          --replace-fail 'export const AUTO_UPDATE_CHECKS_DEFAULT = true;' \
                         'export const AUTO_UPDATE_CHECKS_DEFAULT = false;'
      '';
    }))
  ];
}
