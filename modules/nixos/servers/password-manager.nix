{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  cfg = config.server.services.password-manager;
in
{
  options.server.services.password-manager = {
    enable = lib.mkEnableOption {
      description = "A password manager.";
    };

    dataDir = lib.mkOption {
      description = "Where the service data is stored";
      type = types.path;
      default = "/var/lib/vaultwarden";
    };

    domain = lib.mkOption {
      description = "The domain to responde to.";
      type = types.str;
    };

    environmentFile = lib.mkOption {
      description = "Path to a file holding secret environment variables passed to the password manager server.";
      type = types.nullOr types.path;
      default = null;
    };
  };

  config =
    let
      containerName = "password-manager";
      inherit (config.server.services) reverse-proxy;
      inherit (config.containers.${containerName}.config.services) vaultwarden;
    in
    lib.mkIf cfg.enable {
      server = {
        services.reverse-proxy.virtualHosts.${cfg.domain} = {
          inherit containerName;
          port = vaultwarden.config.ROCKET_PORT;
          public = true;
        };

        containers.${containerName} = {
          secrets = {
            "${containerName}/secrets.env" = lib.mkIf (cfg.environmentFile != null) {
              path = cfg.environmentFile;
            };
          };

          dataDirs.vaultwarden = {
            host.path = cfg.dataDir;
            container = with config.containers.${containerName}.config.users; {
              # Hard coded and not exposed in Nixpkgs :(
              # See https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/security/vaultwarden/default.nix
              inherit (users.vaultwarden) uid;
              inherit (groups.vaultwarden) gid;
              path = "/var/lib/vaultwarden";
            };
          };
        };
      };

      containers.${containerName} = {
        config = {
          networking.firewall.allowedTCPPorts = [ vaultwarden.config.ROCKET_PORT ];

          users = rec {
            groups.vaultwarden.gid = users.vaultwarden.uid;
            users.vaultwarden.uid = 679;
          };

          services.vaultwarden = {
            enable = true;
            configureNginx = false;
            environmentFile = lib.mkIf (
              cfg.environmentFile != null
            ) "/run/credentials/${containerName}/secrets.env";
            config = {
              ROCKET_ADDRESS = "::";
              ROCKET_PORT = 8222;

              DOMAIN = reverse-proxy.virtualHosts.${cfg.domain}.origin;
              SMTP_FROM = "no-reply@${cfg.domain}";

              SIGNUPS_ALLOWED = false;
              INVITATIONS_ALLOWED = false;
              SSO_ENABLED = true;
              SSO_ONLY = true;
              SSO_SIGNUPS_MATCH_EMAIL = true;
              SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION = false;
              SSO_PKCE = true;

              PUSH_ENABLED = true;
              SHOW_PASSWORD_HINT = false;
            };
          };
        };
      };

      virtualisation.vmVariant = {
        server.services.password-manager.environmentFile = lib.mkForce null;
        containers.${containerName}.config.services.vaultwarden = {
          environmentFile = lib.mkForce [ ];
          config.EMAIL_VERIFICATION_ENABLED = lib.mkForce false;
          config.SSO_ENABLED = lib.mkForce false;
          config.PUSH_ENABLED = lib.mkForce false;
        };
      };
    };
}
