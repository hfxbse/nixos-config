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
      description = "Directory to store the service files on the host system via a mount";
      type = lib.types.path;
    };

    systemStateVersion = lib.mkOption {
      description = "System state version used for the container. Do not change it after the container has been created.";
      type = lib.types.str;
    };
  };

  config =
    let
      container = config.containers.immich;
      immich = container.config.services.immich;
      postgresql = container.config.services.postgresql;
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

      containers.immich = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "10.0.0.1";
        localAddress = "10.0.0.2";
        # Failes to mount the nix store using this option
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
          };

        config = {
          networking = {
            firewall.enable = true;

            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            useHostResolvConf = lib.mkForce false;
          };

          services.postgresql.package = pkgs.postgresql_16;
          services.immich = {
            enable = true;

            host = container.localAddress;
            openFirewall = true;

            inherit (cfg) accelerationDevices;
            machine-learning.enable = true;
          };

          system.stateVersion = cfg.systemStateVersion;
        };
      };
    };
}
