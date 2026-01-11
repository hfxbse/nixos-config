{ lib, ... }:
{
  networking.interfaces = lib.mkForce { };
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    netdevs."20-br0" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br0";
      };
    };
    networks = {
      "30-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };
      "40-br0" = {
        matchConfig.Name = "br0";
        networkConfig.DHCP = "ipv4";
        linkConfig.RequiredForOnline = "carrier";
      };
    };
  };

  services.hostapd = {
    enable = true;
    radios.wlp58s0 = {
      settings.bridge = "br0";

      wifi4.enable = true;
      wifi5.enable = true;

      channel = 1;

      countryCode = "DE";
      networks.wlp58s0 = {
        ssid = "FRITZ!Box 7490-62";
        authentication = {
          mode = "wpa2-sha256";
          wpaPasswordFile = "/var/lib/wifi-bridge-psk";
        };
      };
    };
  };
}
