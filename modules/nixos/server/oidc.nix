{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.oidc;
in
{

  options.server.oidc = {
    enable = lib.mkEnableOption "a OpenID Connect server in a container";

    dataDir = lib.mkOption {
      type = lib.types.path;
    };

    secretsFile = lib.mkOption {
      # See https://search.nixos.org/options?channel=unstable&show=services.pocket-id.environmentFile
      type = lib.types.path;
    };

    systemStateVersion = lib.mkOption {
      description = "System state version used for the container. Do not change it after the container has been created.";
      type = lib.types.str;
    };

    virtualHostName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    clients = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Container names which need to access the OpenID Connect server";
    };
  };

  config =
    let
      container = config.containers.oidc;
      pocketId = container.config.services.pocket-id;

      virtualHost = config.server.reverse-proxy.enable && cfg.virtualHostName != null;

      origin =
        port:
        let
          prefix = if virtualHost then "https://${cfg.virtualHostName}" else "http://localhost";
        in
        if port != 443 && port != 80 then "${prefix}:${builtins.toString port}" else prefix;
    in
    lib.mkIf (config.server.enable && cfg.enable) {
      server = {
        stateDirectories.oidc = [ cfg.dataDir ];
        network.oidc = {
          subnetPrefix = "10.0.252";
          internetAccess = true;
          forwardPorts = [
            {
              port = pocketId.settings.PORT;
              external = !config.server.reverse-proxy.enable;
              allowVNets = lib.optional config.server.reverse-proxy.enable "reverse-proxy";
            }
          ];
        };
      };

      server.reverse-proxy.virtualHosts = lib.mkIf (cfg.virtualHostName != null) {
        ${cfg.virtualHostName} = {
          public = true;
          target.host = container.localAddress;
          target.port = pocketId.settings.PORT;

          # See https://pocket-id.org/docs/advanced/nginx-reverse-proxy
          extraConfig = ''
            proxy_busy_buffers_size   512k;
            proxy_buffers   4 512k;
            proxy_buffer_size   256k;
          '';
        };
      };

      virtualisation.vmVariant.containers.oidc.config.services.pocket-id.settings = {
        APP_URL = lib.mkForce (origin (if virtualHost then 8443 else pocketId.settings.PORT));
      };

      # Directory permission reset after every container restart
      # The pocked-id services is NOT restarted when the container is restarted
      # The container does not "boot", meaning the usual mulit-user.target trigger
      # does not work.
      # Therefore, this workaround running on the host machine.
      systemd.services.pocket-id-data =
        let
          trigger = [ "container@oidc.service" ];
        in
        {
          description = "Fixes the file permissions for the data stored by Pocked ID";
          wantedBy = trigger;
          partOf = trigger;
          after = trigger;
          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              let
                nixos-container = lib.getExe pkgs.nixos-container;
              in
              lib.getExe (
                pkgs.writeShellScriptBin "pocked-id-data" ''
                  ${nixos-container} run oidc -- chown ${pocketId.user}:${pocketId.group} \
                    -R -L ${pocketId.dataDir};
                ''
              );
          };
        };

      containers =
        lib.genAttrs cfg.clients (name: {
          config.networking.hosts = lib.mkIf config.server.reverse-proxy.enable {
            "${config.server.network.reverse-proxy.subnetPrefix}.2" = [ cfg.virtualHostName ];
          };
        })
        // {
          oidc = {
            autoStart = true;
            privateUsers = "pick";

            bindMounts = {
              data = {
                mountPoint = "${pocketId.dataDir}:idmap";
                hostPath = cfg.dataDir;
                isReadOnly = false;
              };

              secrets = {
                mountPoint = pocketId.environmentFile;
                hostPath = cfg.secretsFile;
                isReadOnly = true;
              };
            };

            config = {
              services.pocket-id = {
                enable = true;
                settings = {
                  ALLOW_USER_SIGNUPS = "withToken";
                  APP_NAME =
                    let
                      parts = lib.splitString "." cfg.virtualHostName;
                    in
                    builtins.concatStringsSep "." (lib.takeEnd 2 parts);

                  APP_URL = origin (if virtualHost then 443 else pocketId.settings.PORT);
                  EMAIL_LOGIN_NOTIFICATION_ENABLED = true;
                  PORT = 1411;
                  SMTP_FROM = lib.mkIf (cfg.virtualHostName != null) "no-reply@${cfg.virtualHostName}";
                  TRUST_PROXY = true;
                  UI_CONFIG_DISABLED = true;

                  # See https://pocket-id.org/docs/client-examples/beszel
                  EMAILS_VERIFIED = config.server.monitoring.enable;
                };

                environmentFile = "/run/secrets/pocket-id";
              };

              system.stateVersion = cfg.systemStateVersion;
            };
          };
        };
    };
}
