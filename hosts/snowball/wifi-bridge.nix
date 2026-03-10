{ lib, ... }:
let
  bridgeName = "br-host";
in
{
  networking.interfaces = lib.mkForce { };
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    netdevs."20-${bridgeName}" = {
      netdevConfig = {
        Kind = "bridge";
        Name = bridgeName;
      };
    };

    networks = {
      "30-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig.Bridge = bridgeName;
        linkConfig.RequiredForOnline = "enslaved";
      };
      "40-${bridgeName}" = {
        matchConfig.Name = bridgeName;
        networkConfig.DHCP = "ipv4";
        linkConfig.RequiredForOnline = "carrier";
      };
    };
  };

  virtualisation.vmVariant.services.hostapd.enable = lib.mkForce false;
  services.hostapd = {
    enable = true;
    radios.wlp58s0 = {
      settings.bridge = bridgeName;

      wifi4.enable = true;
      wifi5.enable = true;

      channel = 1;

      countryCode = "DE";
      networks.wlp58s0 = {
        ssid = "FRITZ!Box 7490-62";
        authentication = {
          mode = "wpa2-sha256";
          wpaPasswordFile = "/var/lib/secrets/wifi-bridge-psk";
        };
      };
    };
  };
}
