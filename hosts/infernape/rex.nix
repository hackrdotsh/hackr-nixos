{ inputs, username, ... }: {
  imports = [ inputs.rex.nixosModules.default ];

  services.rex.loginServer = {
    enable = true;
    accounts.${username}.principals = [ "tailscale:hackrdotsh@github" ];
    tailscaleServe.enable = true;
  };
}
