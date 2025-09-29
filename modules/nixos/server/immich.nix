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

  config = lib.mkIf (config.server.enable && cfg.enable) {
    containers.immich =
      let
        mediaLocation = "/var/lib/immich";
      in
      {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "${config.server.hostAddressSubnet}.1";
        localAddress = "${config.server.hostAddressSubnet}.2";
        # Failes to mount the nix store using this option
        # privateUsers = "pick";

        bindMounts.media = lib.mkIf (cfg.mediaLocation != null) {
          mountPoint = mediaLocation;
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
            openFirewall = true;
            inherit mediaLocation;
            inherit (cfg) accelerationDevices;
            machine-learning.enable = false;
          };

          system.stateVersion = cfg.systemStateVersion;
        };
      };
  };
}
