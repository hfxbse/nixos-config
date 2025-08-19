{
  config,
  lib,
  ...
}:
let
  cfg = config.desktop.networking;
in
{
  options.desktop.networking.enable = lib.mkEnableOption "dynamic networking for interactive computers";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
    users.users.${config.user.name}.extraGroups = [ "networkmanager" ];

    # Allow sharing network connections on demand
    networking.firewall = {
      enable = lib.mkDefault true;

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
