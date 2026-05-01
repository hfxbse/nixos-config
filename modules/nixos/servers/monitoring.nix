{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  cfg = config.server.services.monitoring;
in
{
  options.server.services.monitoring = {
    ui = {
      enable = lib.mkEnableOption {
        description = "A web UI for monitoring activities of devices.";
      };

      domain = lib.mkOption {
        description = "The domain to responde to.";
        type = types.str;
      };

      dataDir = lib.mkOption {
        description = "Where the service data is stored";
        type = types.path;
        default = "/var/lib/beszel-hub";
      };
    };

    agent = {
      enable = lib.mkEnableOption {
        description = "A monitoring agent.";
      };

      environmentFile = lib.mkOption {
        description = "Path to the environment file which holdes the secrets.";
        type = types.path;
      };
    };
  };

  config =
    let
      containerName = "monitoring";
      inherit (config.server.services) reverse-proxy;
      inherit (config.containers.${containerName}.config.services.beszel) hub;
    in
    lib.mkMerge [
      (lib.mkIf cfg.ui.enable {
        server = {
          services.reverse-proxy.virtualHosts.${cfg.ui.domain} = {
            inherit containerName;
            port = hub.port;
          };

          containers.${containerName} = {
            dataDirs.hub = {
              host.path = cfg.ui.dataDir;
              container = with config.containers.${containerName}.config.users; {
                inherit (users.beszel-hub) uid;
                inherit (groups.beszel-hub) gid;
                path = hub.dataDir;
              };
            };
          };
        };

        containers.${containerName} = {
          bindMounts = lib.mkIf cfg.agent.enable {
            host-agent = {
              hostPath = "/run/beszel-agent/host.socket";
              mountPoint = "/run/host-agent.socket:idmap";
              isReadOnly = false;
            };
          };

          config = {
            networking.firewall.allowedTCPPorts = [ hub.port ];

            users = rec {
              groups.${users.beszel-hub.group}.gid = users.beszel-hub.uid;
              users.beszel-hub = {
                uid = 932;
                group = "beszel-hub";
              };
            };

            systemd.services.beszel-hub.serviceConfig.DynamicUser = lib.mkForce false;
            services.beszel.hub = {
              enable = true;
              host = "[::]";
              environment = {
                APP_URL = reverse-proxy.virtualHosts.${cfg.ui.domain}.origin;
                USER_CREATION = "true";
                DISABLE_PASSWORD_AUTH = "true";
              };
            };
          };
        };

        virtualisation.vmVariant = {
          containers.${containerName}.config.services.beszel.hub.environment = {
            DISABLE_PASSWORD_AUTH = lib.mkForce "false";
          };
        };
      })
      (lib.mkIf cfg.agent.enable {
        services.beszel.agent = {
          enable = true;
          smartmon.enable = true;
          environmentFile = cfg.agent.environmentFile;
          environment = {
            LISTEN = lib.mkIf cfg.ui.enable "/run/beszel-agent/host.socket";
          };
        };

        systemd.services = lib.mkIf cfg.ui.enable {
          beszel-agent.serviceConfig.RuntimeDirectory = "beszel-agent";
          "container@${containerName}" = rec {
            after = requires;
            bindsTo = requires;
            requires = [ "beszel-agent.service" ];
          };
        };

        containers.${containerName}.config.systemd.services.agent-setup = lib.mkIf cfg.ui.enable rec {
          wantedBy = [ "multi-user.target" ];
          before = requires;
          requires = [ "beszel-hub.service" ];
          serviceConfig.Type = "oneshot";
          script = "chown beszel-hub:beszel-hub /run/host-agent.socket";
        };

        virtualisation.vmVariant = {
          systemd.services."dummy-secrets@beszel-agent" = {
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Type = "oneshot";
            script = ''
              mkdir -p ''$(dirname "${cfg.agent.environmentFile}");
              echo KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPoKS4DKyku7Eew8zi9RlTNh+Hcf7iznCnlAN9vANVg" > "${cfg.agent.environmentFile}"
            '';
          };
        };
      })
    ];
}
