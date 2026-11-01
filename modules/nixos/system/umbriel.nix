{ inputs, lib, ... }:
{
  imports = [ inputs.umbriel.nixosModules.default ];

  programs.umbriel.enable = true;
  services.displayManager.defaultSession = lib.mkForce "umbriel";
}
