{ ... }:
{
  imports = [
    ./dns.nix
    ./immich.nix
    ./tls.nix
  ];

  server.ingress.wan = "br-lan";
  virtualisation.vmVariant = {
    server.services.dummy.enable = true;
    server.services.dummy-http = {
      enable = true;
      domain = "example.fxbse.com";
    };

    server.services.reverse-proxy.ports = {
      http = 8080;
      https = 8443;
    };
  };
}
