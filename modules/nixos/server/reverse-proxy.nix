{
  config,
  lib,
  ...
}:
let
  serverName = "reverse-proxy";
  cfg = config.server.${serverName};
in
{

  options.server.${serverName} = {
    enable = lib.mkEnableOption "a reverse-proxy in a container";

    systemStateVersion = lib.mkOption {
      description = "System state version used for the container. Do not change it after the container has been created.";
      type = lib.types.str;
    };

    virtualHosts = lib.mkOption {
      default = [ ];
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
          {
            options = {
              target = {
                host = lib.mkOption {
                  type = lib.types.str;
                  example = "example.com";
                };

                port = lib.mkOption {
                  default = 80;
                  type = lib.types.ints.positive;
                };
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf (config.server.enable && cfg.enable) {
    server.network.${serverName} = {
      subnetPrefix = "10.0.253";
      forwardPorts = [
        {
          port = 80;
          vmHostPort = 8080;
          external = true;
        }
        {
          port = 443;
          vmHostPort = 8443;
          external = true;
        }
      ];
    };

    containers.${serverName} = {
      autoStart = true;
      privateUsers = "pick";

      config = {
        services.nginx = {
          enable = true;

          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;

          virtualHosts = lib.genAttrs (builtins.attrNames cfg.virtualHosts) (
            name:
            let
              virtualHost = cfg.virtualHosts.${name};
            in
            {
              locations."/" = {
                proxyPass = "http://${virtualHost.target.host}:${builtins.toString virtualHost.target.port}";
                proxyWebsockets = true;
              };
            }
          );
        };

        system.stateVersion = cfg.systemStateVersion;
      };
    };
  };
}
