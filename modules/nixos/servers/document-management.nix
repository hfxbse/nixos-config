{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  cfg = config.server.services.document-management;
in
{
  options.server.services.document-management = {
    enable = lib.mkEnableOption {
      description = "A document management system.";
    };

    dataDir = lib.mkOption {
      description = "Where the service data is stored";
      type = types.path;
      default = "/var/lib/papra";
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
      containerName = "doc-management";
      inherit (config.server.services) reverse-proxy;
      inherit (config.containers.${containerName}.config.services) papra;
    in
    lib.mkIf cfg.enable {
      server = {
        services.reverse-proxy.virtualHosts.${cfg.domain} = {
          inherit containerName;
          port = papra.environment.PORT;
          public = false;
        };

        containers.${containerName} = {
          secrets."${containerName}/secrets.env".path = cfg.environmentFile;
          dataDirs.papra = {
            host.path = cfg.dataDir;
            container = with config.containers.${containerName}.config.users; {
              inherit (users.${papra.user}) uid;
              inherit (groups.${papra.user}) gid;
              path = "/var/lib/papra"; # As defined as default in the nixpkgs module
            };
          };
        };
      };

      containers.${containerName} = {
        config = {
          networking.firewall.allowedTCPPorts = [ papra.environment.PORT ];

          users = with papra; rec {
            groups.${group}.gid = users.${user}.uid;
            users.${user}.uid = 713;
          };

          services.papra ={
            enable = true;
            # Cannot use LoadCredential.
            # This gets added to the service config directly.
            environmentFile = "/run/credentials/${containerName}/secrets.env";
            environment = {
              PAPRA_VERSION = papra.package.version;
              APP_BASE_URL = reverse-proxy.virtualHosts.${cfg.domain}.origin;
              PORT = 1221;
              SERVER_HOSTNAME = "::";

              AUTH_PROVIDERS_EMAIL_IS_ENABLED = false;
              AUTH_IS_PASSWORD_RESET_ENABLED = false;
              AUTH_IP_ADDRESS_HEADERS = "x-forwarded-for";
              AUTH_IS_EMAIL_VERIFICATION_REQUIRED = true;
              AUTH_IS_REGISTRATION_ENABLED = false;

              DOCUMENT_STORAGE_MAX_UPLOAD_SIZE = 536870912;  # 512 MiB
            };
          };
        };
      };

      virtualisation.vmVariant = {
        containers.${containerName}.config.services.papra.environment = {
          AUTH_PROVIDERS_EMAIL_IS_ENABLED = lib.mkForce true;
          AUTH_IS_EMAIL_VERIFICATION_REQUIRED = lib.mkForce false;
          AUTH_IS_REGISTRATION_ENABLED = lib.mkForce true;
        };

        systemd.services."dummy-secrets@papra" = {
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir -p ''$(dirname "${cfg.environmentFile}");
            echo "" > "${cfg.environmentFile}"
          '';
        };
      };
    };
}
