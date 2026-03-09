{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  cfg = config.server.services.oidc;
in
{
  options.server.services.oidc = {
    enable = lib.mkEnableOption {
      description = "A OIDC provider.";
    };

    dataDir = lib.mkOption {
      description = "Where the service data is stored";
      type = types.path;
      default = "/var/lib/pocket-id";
    };

    domain = lib.mkOption {
      description = "The domain to responde to.";
      type = types.str;
    };

    environmentFile = lib.mkOption {
      description = "Path to a file holding secret environment variables passed to the OIDC provider.";
      type = types.path;
    };
  };

  config =
    let
      containerName = "oidc";
      inherit (config.server.services) reverse-proxy;
      inherit (config.containers.${containerName}.config.services) pocket-id;
    in
    lib.mkIf cfg.enable {
      server = {
        services.reverse-proxy.virtualHosts.${cfg.domain} = {
          inherit containerName;
          port = pocket-id.settings.PORT;
        };

        containers.oidc = {
          secrets."${containerName}/secrets.env".path = cfg.environmentFile;
          dataDirs.pocket-id = {
            host.path = cfg.dataDir;
            container = with config.containers.${containerName}.config.users; {
              inherit (users.pocket-id) uid;
              inherit (groups.pocket-id) gid;
              path = pocket-id.dataDir;
            };
          };
        };
      };

      containers.${containerName} = {
        config = {
          networking.firewall.allowedTCPPorts = [ pocket-id.settings.PORT ];

          users = rec {
            groups.pocket-id.gid = users.pocket-id.uid;
            users.pocket-id = {
              home = lib.mkForce "/var/empty"; # Reset to the default value
              uid = 789;
            };
          };

          services.pocket-id = {
            enable = true;
            dataDir = "/var/lib/pocket-id";
            settings = {
              ALLOW_USER_SIGNUPS = "withToken";
              APP_NAME = lib.pipe cfg.domain [
                (lib.splitString ".")
                (lib.takeEnd 2)
                (builtins.concatStringsSep ".")
              ];

              APP_URL =
                with reverse-proxy;
                "https://${cfg.domain}${lib.optionalString (ports.https != 443) (toString ports.https)}";

              EMAIL_LOGIN_NOTIFICATION_ENABLED = true;
              EMAIL_VERIFICATION_ENABLED = true;
              PORT = 1411;
              SMTP_FROM = "no-reply@${cfg.domain}";
              TRUST_PROXY = true;
              UI_CONFIG_DISABLED = true;
            };

            # Cannot use LoadCredential.
            # This gets added to the service config directly.
            environmentFile = "/run/credentials/${containerName}/secrets.env";
          };
        };
      };

      virtualisation.vmVariant = {
        containers.${containerName}.config.services.pocket-id.settings = {
          EMAIL_VERIFICATION_ENABLED = lib.mkForce false;
        };

        systemd.services."dummy-secrets@pocket-id" = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir -p ''$(dirname "${cfg.environmentFile}");
            echo ENCRYPTION_KEY=1234567890987654321 > "${cfg.environmentFile}"
          '';
        };
      };
    };
}
