{ ... }:
{
  imports = [
    ./immich.nix
    ./tls.nix
  ];

  server.services.dummy.enable = true;
  server.services.dummy-http = {
    enable = true;
    domain = "example.fxbse.com";
  };

  server.services.reverse-proxy.ports = {
    http = 8080;
    https = 8443;
  };

  server.ingress.wan = "br-lan";
}
