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
      credentialsFile = "/var/lib/secrets/porkbun/${domain}";
    };
  };

  virtualisation.vmVariant.security.acme.certs.${domain} = {
    dnsProvider = lib.mkForce "";
    credentialsFile = lib.mkForce null;
  };
}
