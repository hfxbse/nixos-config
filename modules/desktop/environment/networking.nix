{
  config,
  lib,
  ...
}:
let
  cfg = config.desktop.environment.networking;
in
{
  options.desktop.environment.networking.enable =
    lib.mkEnableOption "If dynamic networking for interactive computers should be used."
    // {
      default = config.desktop.environment.enable;
    };

  config = lib.mkIf cfg.enable {
    # Disables scripted networking configured by NixOS facter
    networking.interfaces = lib.mkForce { };
    networking.networkmanager.enable = true;
    users.users.${config.user.name}.extraGroups = [ "networkmanager" ];

    # Required for enterprise WiFi like eduroam via NetworkManager
    networking.wireless.enableHardening = false;

    # Allow sharing network connections on demand
    networking.firewall = {
      enable = lib.mkDefault true;
      checkReversePath = "loose"; # Required for VPN connections to work

      allowedTCPPorts = [
        53 # DNS
      ];

      allowedUDPPorts = [
        53 # DNS
        67 # DHCP
      ];
    };
  };
}
