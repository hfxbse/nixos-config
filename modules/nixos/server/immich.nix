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

    systemStateVersion = lib.mkOption {
      description = "System state version used for the container. Do not change it after the container has been created.";
      type = lib.types.str;
    };

    machine-learning.enable = lib.mkEnableOption "machine-learning support" // {
      default = true;
    };
  };

  config =
    let
      container = config.containers.immich;
      immich = container.config.services.immich;
      postgresql = container.config.services.postgresql;

      storeDataOnHost = cfg.dataDir != null;
    in
    lib.mkIf (config.server.enable && cfg.enable) {
      networking.firewall.allowedTCPPorts = [ immich.port ];
      networking.nat.forwardPorts = [
        {
          sourcePort = immich.port;
          proto = "tcp";
          destination = "${container.localAddress}:${builtins.toString immich.port}";
        }
      ];

      virtualisation.vmVariant.virtualisation.forwardPorts = [
        {
          from = "host";
          host.port = immich.port;
          guest.port = immich.port;
        }
      ];

      systemd.services."container@immich".serviceConfig = lib.mkIf storeDataOnHost {
        StateDirectory =
          let
            relativePath = lib.removePrefix "/var/lib/" cfg.dataDir;
          in
          [
            "${relativePath}/media"
            "${relativePath}/database"
          ];
      };

      containers.immich = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "10.0.255.1";
        localAddress = "10.0.255.2";
        # Failes to mount the nix store using this option
        # privateUsers = "pick";

        bindMounts =
          lib.genAttrs cfg.accelerationDevices (path: {
            mountPoint = path;
            hostPath = path;
            isReadOnly = false;
          })
          // lib.mkIf storeDataOnHost {
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
            networking = {
              firewall.enable = true;

              # Use systemd-resolved inside the container
              # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
              useHostResolvConf = lib.mkForce false;
            };

            # DNS is required to download the machine learning models
            services.resolved.enable = true;

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
