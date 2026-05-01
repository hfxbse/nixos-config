{ lib, ... }:
let
  domain = "fxbse.com";
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "web@fhaas.org";
    certs."fxbse.com" = {
      domain = "*.${domain}";
      dnsProvider = "porkbun";
      dnsPropagationCheck = true;
      environmentFile = "/var/lib/secrets/porkbun/${domain}";
    };
  };

  server.services.reverse-proxy.defaults.acmeCertName = domain;

  virtualisation.vmVariant.security.acme.certs.${domain} = {
    dnsProvider = lib.mkForce "";
    environmentFile = lib.mkForce null;
  };
}
