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

    mediaLocation = lib.mkOption {
      description = "Directory to store the media files on the host system via a mount";
      type = lib.types.nullOr lib.types.path;
      default = null;
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

        bindMounts.media = lib.mkIf (cfg.mediaLocation != null) {
          mountPoint = immich.mediaLocation;
          hostPath = cfg.mediaLocation;
          isReadOnly = false;
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
          };

          system.stateVersion = cfg.systemStateVersion;
        };
      };
    };
}
