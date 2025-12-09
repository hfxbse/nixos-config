{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.monitoring;
in
{
  options.server.monitoring = {
    enable = lib.mkEnableOption "monitoring on the host system";
    fileSystems = lib.mkOption {
      description = "Which filesystems to include in the monitoring. The file system mounted at / is automatically added.";
      type = lib.types.listOf lib.types.path;
      default = [ ];
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/beszel-agent";
    };

    secretsFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ config.services.beszel.hub.port ];
    services.beszel.hub = {
      enable = true;
      host = "0.0.0.0";
    };

    # See https://discourse.nixos.org/t/systemd-exporter-couldnt-get-dbus-connection-read-unix-run-dbus-system-bus-socket-recvmsg-connection-reset-by-peer/64367/4
    services.dbus.implementation = "broker";

    services.beszel.agent = {
      enable = true;
      environmentFile = cfg.secretsFile;

      environment = {
        DATA_DIR = cfg.dataDir;
        EXTRA_FILESYSTEMS = lib.concatStringsSep "," cfg.fileSystems;
        HUB_URL = "http://127.0.0.1:${builtins.toString config.services.beszel.hub.port}";
        SERVICE_PATTERNS = "beszel*,docker*,kubelet*,container@*";
      };

      extraPath = with pkgs; [ smartmontools ];
    };

    systemd.services.beszel-agent.serviceConfig =
      let
        smartCapabilities = [
          # See https://beszel.dev/guide/smart-data#binary-agent
          "CAP_SYS_RAWIO"
          "CAP_SYS_ADMIN"
        ];
      in
      {
        NoNewPrivileges = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
        SupplementaryGroups = [ "disk" ];

        AmbientCapabilities = smartCapabilities;
        CapabilityBoundingSet = smartCapabilities;
      };
  };
}
