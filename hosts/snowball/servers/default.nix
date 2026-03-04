{ ... }:
{
  imports = [
    ./immich.nix
    ./tls.nix
  ];

  server.services.dummy.enable = true;
  server.router.wan = "br-lan";
}
