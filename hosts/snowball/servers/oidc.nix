{ ... }:
{
  server.services.oidc = {
    enable = true;
    domain = "account.fxbse.com";
    environmentFile = "/var/lib/secrets/pocket-id.env";
  };
}
