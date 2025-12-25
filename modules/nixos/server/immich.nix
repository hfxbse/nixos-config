{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.immich;
in
{
  options.server.immich = {
    enable = lib.mkEnableOption "Immich within a container";

    accelerationDevices = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
    };

    dataDir = lib.mkOption {
      # Using StateDir in the service definition results the directory to be created in /var/lib
      # See https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#RuntimeDirectory=
      description = "Directory name to store the service files on the host system at /var/lib via a mount";
      type = lib.types.path;
    };

    secretSettingsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    systemStateVersion = lib.mkOption {
      description = "System state version used for the container. Do not change it after the container has been created.";
      type = lib.types.str;
    };

    machine-learning.enable = lib.mkEnableOption "machine-learning support" // {
      default = true;
    };

    virtualHostName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config =
    let
      container = config.containers.immich;
      immich = container.config.services.immich;
      postgresql = container.config.services.postgresql;

      secretSettings = "/run/secrets/immich/settings";
    in
    lib.mkIf (config.server.enable && cfg.enable) {

      server = {
        stateDirectories.immich = [
          "${cfg.dataDir}/database"
          cfg.secretSettingsDir
        ]
        ++ config.server.permissionMappings.immich-server.paths;

        permissionMappings = {
          immich-server = {
            user.nameOnServer = immich.user;
            group.nameOnServer = immich.group;
            server = "immich";
            paths = [ immich.mediaLocation ];
          };

          immich-db = {
            # Hard coded names to avoid infinite recursion
            user.nameOnServer = "postgres";
            group.nameOnServer = "postgres";
            server = "immich";
            paths = [ postgresql.dataDir ];
          };
        };

        network.immich = {
          subnetPrefix = "10.0.255";
          internetAccess = true;
          forwardPorts = with config.server; [
            {
              port = immich.port;
              external = !reverse-proxy.enable;
              allowVNets = lib.mkIf reverse-proxy.enable [ "reverse-proxy" ];
            }
          ];
        };

        oidc.clients = [ "immich" ];

        reverse-proxy.virtualHosts = lib.mkIf (cfg.virtualHostName != null) {
          ${cfg.virtualHostName} = {
            public = true;
            target.host = container.localAddress;
            target.port = immich.port;

            # https://docs.immich.app/administration/reverse-proxy/#nginx-example-config
            extraConfig = ''
              client_max_body_size 50000M;
              proxy_buffering off;
              proxy_request_buffering off;
              client_body_buffer_size 1024k;
            '';
          };
        };
      };

      containers.immich = {
        autoStart = true;
        # FUSE-based filesystems cannot be id-mapped :(
        # privateUsers = "pick";

        bindMounts =
          lib.genAttrs cfg.accelerationDevices (path: {
            mountPoint = path;
            hostPath = path;
            isReadOnly = false;
          })
          // {
            media = {
              mountPoint = immich.mediaLocation;
              hostPath = "${cfg.dataDir}/media";
              isReadOnly = false;
            };

            database = {
              mountPoint = postgresql.dataDir;
              hostPath = "${cfg.dataDir}/database";
              isReadOnly = false;
            };

            secret-settings = lib.mkIf (cfg.secretSettingsDir != null) {
              mountPoint = secretSettings;
              hostPath = cfg.secretSettingsDir;
              isReadOnly = true;
            };
          };

        allowedDevices = builtins.map (node: {
          inherit node;
          modifier = "rwm";
        }) (cfg.accelerationDevices ++ [ "/dev/net/tun" ]);

        config =
          let
            machine-learning-dir = "/var/lib/immich-machine-learning";
          in
          {
            ids = with config.server.permissionMappings; {
              uids.postgres = lib.mkForce immich-db.user.uid;
              gids.postgres = lib.mkForce immich-db.group.gid;
            };

            services.postgresql.package = pkgs.postgresql_16;
            services.immich = with config.server; {
              enable = true;
              database.enableVectors = false;

              host = container.localAddress;
              openFirewall = true;

              inherit (cfg) accelerationDevices;
              machine-learning = {
                enable = cfg.machine-learning.enable;
                environment = {
                  MPLCONFIGDIR = machine-learning-dir;
                };
              };

              # List of options https://docs.immich.app/install/config-file/
              settings.machineLearning.enabled = cfg.machine-learning.enable;

              settings.server = {
                externalDomain = "https://${cfg.virtualHostName}";
                publicUsers = false;
              };

              settings.passwordLogin.enabled = !oidc.enable;
              settings.oauth = lib.mkIf oidc.enable {
                enabled = true;
                autoLaunch = true;

                issuerUrl._secret = "${secretSettings}/oauth/issuerUrl";
                clientId._secret = "${secretSettings}/oauth/clientId";
                clientSecret._secret = "${secretSettings}/oauth/clientSecret";
              };

              settings.notifications.smtp =
                let
                  secret = name: "${secretSettings}/notifications/smtp/${name}";
                in
                {
                  enabled = true;
                  from = "no-reply@${cfg.virtualHostName}";
                  transport = {
                    host._secret = secret "host";
                    ignoreCert = false;
                    password._secret = secret "password";
                    port = 465;
                    secure = true;
                    username._secret = secret "username";
                  };
                };
            };

            systemd.services."immich-machine-learning".serviceConfig = {
              StateDirectory = [
                (lib.removePrefix "/var/lib/" machine-learning-dir)
              ];
            };

            system.stateVersion = cfg.systemStateVersion;
          };
      };
    };
}
