{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.monitoring;

  uiServerName = "monitoring-ui";
  container = config.containers.${uiServerName};
  cfgBeszelHub = container.config.services.beszel.hub;
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

    webUi = {
      enable = lib.mkEnableOption "the monitoring web interface";
      dataDir = lib.mkOption {
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
    };
  };

  config = lib.mkIf cfg.enable {
    server = lib.mkIf cfg.webUi.enable {
      stateDirectories.${uiServerName} = [ cfgBeszelHub.dataDir ];
      network.${uiServerName} = {
        subnetPrefix = "10.0.251";
        internetAccess = true; # Needed for notifications
        forwardPorts = [
          {
            port = cfgBeszelHub.port;
            allowVNets = lib.mkIf config.server.reverse-proxy.enable [ "reverse-proxy" ];
          }
        ];
      };

      oidc.clients = [ uiServerName ];

      reverse-proxy.virtualHosts = lib.mkIf (cfg.webUi.virtualHostName != null) {
        ${cfg.webUi.virtualHostName} = {
          target.host = container.localAddress;
          target.port = cfgBeszelHub.port;
        };
      };
    };

    containers.monitoring-ui = lib.mkIf cfg.webUi.enable {
      autoStart = true;
      privateUsers = "pick";

      bindMounts.data = {
        mountPoint = "${cfgBeszelHub.dataDir}:idmap";
        hostPath = cfg.webUi.dataDir;
        isReadOnly = false;
      };

      config =
        let
          name = "beszel-hub";
        in
        rec {
          users = {
            groups.${name} = { };
            users.${name} = {
              isSystemUser = true;
              group = name;
            };
          };

          services.beszel.hub = {
            enable = true;
            host = "0.0.0.0";
            environment = lib.mkIf config.server.oidc.enable {
              USER_CREATION = "true";
              DISABLE_PASSWORD_AUTH = "true";
            };
          };

          systemd.services.beszel-hub.serviceConfig = {
            User = name;
            Group = users.users.${name}.group;

            # Enabling those breaks the bind mount
            DynamicUser = lib.mkForce false;
            PrivateUsers = lib.mkForce false;
          };

          system.stateVersion = cfg.webUi.systemStateVersion;
        };
    };

    # See https://discourse.nixos.org/t/systemd-exporter-couldnt-get-dbus-connection-read-unix-run-dbus-system-bus-socket-recvmsg-connection-reset-by-peer/64367/4
    services.dbus.implementation = "broker";

    services.beszel.agent = {
      enable = true;
      environmentFile = cfg.secretsFile;

      environment = {
        DATA_DIR = cfg.dataDir;
        EXTRA_FILESYSTEMS = lib.concatStringsSep "," cfg.fileSystems;
        HUB_URL = lib.mkIf cfg.webUi.enable (
          "http://${
            config.server.network.${uiServerName}.subnetPrefix + ".2"
          }:${builtins.toString config.services.beszel.hub.port}"
        );
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
