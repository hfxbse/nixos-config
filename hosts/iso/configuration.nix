{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  cfg = config.setup;
  useSSH = cfg.authorizedKey != null;
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  options.setup = {
    wifi.ssid = lib.mkOption {
      description = "WiFi SSID used for setting up the device";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    wifi.psk = lib.mkOption {
      description = "WiFi password used for setting up the device";
      type = lib.types.nullOr (lib.types.strMatching "[[:print:]]{8,63}");
      default = null;
    };

    authorizedKey = lib.mkOption {
      description = "SSH key used for setting up the device";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = {
    isoImage.squashfsCompression = "gzip -Xcompression-level 1";

    boot.kernelPackages = pkgs.linuxPackages_6_12;
    zramSwap.enable = true;

    services.openssh = lib.mkIf useSSH {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };

    users.users = lib.mkIf useSSH {
      nixos.openssh.authorizedKeys.keys = lib.optional useSSH cfg.authorziedKey;
      root.openssh.authorizedKeys.keys = lib.optional useSSH cfg.authorziedKey;
    };

    networking.wireless = lib.mkIf (cfg.wifi.ssid != null) {
      enable = true;
      userControlled.enable = lib.mkForce false;

      networks."${cfg.wifi.ssid}" = {
        psk = lib.mkif (cfg.wifi.psk != null) cfg.wifi.psk;
      };
    };

    powerManagement.enable = lib.mkForce false;
    services.logind.settings.Login.HandleLidSwitch = "ignore";

    environment.systemPackages = with pkgs; [ htop ];
  };
}
