{ ... }:
{
  imports = [
    ./dns.nix
    ./immich.nix
    ./oidc.nix
    ./tls.nix
  ];

  server.ingress.wan = "br-host";
  virtualisation.vmVariant = {
    # Accessing websites locally via Firefox during testing:
    # Within about:config set `network.dns.localDomains` to be a
    # comma separated list of the required (sub-)domains
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
