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
              sslCertificateDir = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
              };

              extraConfig = lib.mkOption {
                type = lib.types.lines;
                default = '''';
              };

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

  config =
    let
      sslHosts = builtins.filter (name: cfg.virtualHosts.${name}.sslCertificateDir != null) (
        builtins.attrNames cfg.virtualHosts
      );
    in
    lib.mkIf (config.server.enable && cfg.enable) {
      server.stateDirectories.${serverName} = builtins.map (
        host: cfg.virtualHosts.${host}.sslCertificateDir
      ) sslHosts;

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

      services.resolved.enable = true;
      networking.hosts = {
        ${config.containers.${serverName}.localAddress} = builtins.attrNames cfg.virtualHosts;
      };

      containers.${serverName} =
        let
          mountPoint = name: "/var/lib/certs/${name}/";
        in
        {
          autoStart = true;
          privateUsers = "pick";

          bindMounts = lib.genAttrs sslHosts (hostName: {
            mountPoint = "${mountPoint hostName}:idmap";
            hostPath = cfg.virtualHosts.${hostName}.sslCertificateDir;
            isReadOnly = false;
          });

          config = {
            services.nginx = {
              enable = true;

              recommendedGzipSettings = true;
              recommendedOptimisation = true;
              recommendedProxySettings = true;
              recommendedTlsSettings = true;

              virtualHosts = lib.genAttrs (builtins.attrNames cfg.virtualHosts) (
                name:
                let
                  virtualHost = cfg.virtualHosts.${name};
                  useSSL = virtualHost.sslCertificateDir != null;
                in
                {
                  inherit (virtualHost) extraConfig;
                  forceSSL = useSSL;
                  sslCertificate = lib.mkIf useSSL "${mountPoint name}/host.cert";
                  sslCertificateKey = lib.mkIf useSSL "${mountPoint name}/key.pem";

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
