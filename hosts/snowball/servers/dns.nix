{ ... }:
{
  virtualisation.vmVariant.server.services.dns.port = 5533;
  server.services.dns = {
    enable = true;
    filterLists = [
      "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/light.txt"
      "https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/wildcard/light.txt"
      "https://codeberg.org/hagezi/mirror2/raw/branch/main/dns-blocklists/wildcard/light.txt"
    ];

    fallbackDNS.quad9 = {
      tls = "tcp-tls:dns.quad9.net";
      ipAddresses = [
        "2620:fe::fe"
        "2620:fe::9"
      ];
    };
  };
}
