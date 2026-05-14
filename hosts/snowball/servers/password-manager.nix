{ ... }:
{
  server.services.password-manager = {
    enable = true;
    domain = "passwords.fxbse.com";
    environmentFile = "/var/lib/secrets/vaultwarden.env";
  };
}
