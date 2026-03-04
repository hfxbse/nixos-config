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

  server.router.wan = "br-lan";
}
