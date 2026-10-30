{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    sbctl
  ];

  hardware.enableAllFirmware = true;

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot = {
        enable = lib.mkForce false;
        consoleMode = "max";
      };
      limine = {
        enable = true;
        secureBoot.enable = true;
        extraConfig = ''
          term_palette: 1e1e2e;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4
          term_palette_bright: 585b70;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4
          term_background: 1e1e2e
          term_foreground: cdd6f4
          term_background_bright: 585b70
          term_foreground_bright: cdd6f4
        '';
        extraEntries = ''
          /+Windows
          //Windows
            protocol: efi
            path: boot():/EFI/Microsoft/Boot/bootmgfw.efi
        '';
        style = {
          wallpapers = [];
          interface = {
            resolution = "5120x2160";
            helpHidden = true;
            branding = "";
          };
          backdrop = lib.mkForce "1E1E2E";
        };
      };
      timeout = 5;
    };
    plymouth = {
      enable = true;
      theme = lib.mkForce "dark_planet";
      themePackages = with pkgs; [
        (adi1090x-plymouth-themes.override {
          selected_themes = ["dark_planet"];
        })
      ];
    };
    consoleLogLevel = 3;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log-priority=3"
      "rd.systemd.show_status=auto"
    ];
  };
}
