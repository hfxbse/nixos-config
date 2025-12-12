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
      type = lib.types.nullOr (lib.types.strMatching ''^/var/lib/[^/.]+(/[^/.]+)*$'');
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

      storeDataOnHost = cfg.dataDir != null;

      secretSettings = "/run/secrets/immich-settings";
    in
    lib.mkIf (config.server.enable && cfg.enable) {
      server = {
        stateDirectories.immich = [
          "${cfg.dataDir}/media"
          "${cfg.dataDir}/database"
          cfg.secretSettingsDir
        ];

        network.immich = {
          subnetPrefix = "10.0.255";
          internetAccess = true;
          forwardPorts = [
            {
              port = immich.port;
              external = !config.server.reverse-proxy.enable;
              allowVNets = lib.mkIf config.server.reverse-proxy.enable [ "reverse-proxy" ];
            }
          ];
        };

        oidc.clients = [ "immich" ];

        reverse-proxy.virtualHosts = lib.mkIf (cfg.virtualHostName != null) {
          ${cfg.virtualHostName} = {
            public = true;
            target.host = container.localAddress;
            target.port = immich.port;
          };
        };
      };

      containers.immich = {
        autoStart = true;
        # Failes to mount the nix store using this option
        # privateUsers = "pick";

        bindMounts =
          lib.genAttrs cfg.accelerationDevices (path: {
            mountPoint = path;
            hostPath = path;
            isReadOnly = false;
          })
          // {
            media = lib.mkIf storeDataOnHost {
              mountPoint = immich.mediaLocation;
              hostPath = "${cfg.dataDir}/media";
              isReadOnly = false;
            };

            database = lib.mkIf storeDataOnHost {
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
            services.postgresql.package = pkgs.postgresql_16;
            services.immich = {
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

              settings.server.publicUsers = false;
              settings.passwordLogin.enabled = !config.server.oidc.enable;
              settings.oauth = lib.mkIf config.server.oidc.enable {
                enabled = true;
                autoLaunch = true;

                issuerUrl._secret = "${secretSettings}/oauth/issuerUrl";
                clientId._secret = "${secretSettings}/oauth/clientId";
                clientSecret._secret = "${secretSettings}/oauth/clientSecret";
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
