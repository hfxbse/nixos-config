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
                default = "";
              };

              public = lib.mkEnableOption "access from any IP range";

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
      sslHosts = lib.pipe cfg.virtualHosts [
        builtins.attrNames
        (builtins.filter (name: cfg.virtualHosts.${name}.sslCertificateDir != null))
      ];

      mountPoint = name: "/run/secrets/acme/${name}";
    in
    lib.mkIf (config.server.enable && cfg.enable) {
      server = {

        stateDirectories.${serverName} = builtins.map (
          host: cfg.virtualHosts.${host}.sslCertificateDir
        ) sslHosts;

        permissionMappings.acme = {
          user.nameOnServer = "acme";
          group.nameOnServer = "acme";
          server = serverName;
          paths = lib.pipe cfg.virtualHosts [
            builtins.attrNames
            (builtins.map (host: mountPoint host))
          ];
        };

        network.${serverName} =
          let
            oidc = config.server.oidc;
            allowVNets =
              lib.optionals oidc.enable oidc.clients ++ lib.optional config.server.tunnel.enable "tunnel";
          in
          {
            subnetPrefix = "10.0.253";
            forwardPorts = [
              {
                port = 80;
                vmHostPort = 8080;
                external = true;
                inherit allowVNets;
              }
              {
                port = 443;
                vmHostPort = 8443;
                external = true;
                inherit allowVNets;
              }
            ];
          };
      };

      networking.hosts = {
        ${config.containers.${serverName}.localAddress} = builtins.attrNames cfg.virtualHosts;
      };

      containers.${serverName} = {
        autoStart = true;
        privateUsers = "pick";

        bindMounts = lib.genAttrs sslHosts (hostName: {
          mountPoint = "${mountPoint hostName}:idmap";
          hostPath = cfg.virtualHosts.${hostName}.sslCertificateDir;
          isReadOnly = false; # Needed to fix file permissions
        });

        config = {
          users =
            let
              acme = "acme";
              uid = config.users.users.acme.uid;
              gid = config.users.groups.acme.gid;
            in
            lib.mkIf (builtins.length sslHosts > 0) {
              groups.${acme} = { inherit gid; };
              users.nginx.extraGroups = [ acme ];
              users.${acme} = {
                inherit uid;
                isSystemUser = true;
                group = acme;
              };
            };

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
                sslCertificate = lib.mkIf useSSL "${mountPoint name}/cert.pem";
                sslCertificateKey = lib.mkIf useSSL "${mountPoint name}/key.pem";

                locations."/" = {
                  proxyPass = "http://${virtualHost.target.host}:${builtins.toString virtualHost.target.port}";
                  proxyWebsockets = true;
                  extraConfig = lib.mkIf (!virtualHost.public) ''
                    allow 192.168.0.0/16;
                    deny all;
                  '';
                };
              }
            );
          };

          system.stateVersion = cfg.systemStateVersion;
        };
      };
    };
}
