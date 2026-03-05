{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;

  cfg = config.server.services.reverse-proxy;
  containerName = "reverse-proxy";
  bridgeName = "br-http";
  ulaPrefix = "fd00:9d1f:b7b7:1721";
  veth = "vb-http";

  containerNames = lib.pipe cfg.virtualHosts [
    builtins.attrValues
    (map ({ containerName, ... }: containerName))
  ];

  uniqueCerts = lib.pipe cfg.virtualHosts [
    builtins.attrValues
    (map ({ acmeCertName, ... }: acmeCertName))
    lib.unique
  ];
in
{
  options.server.services.reverse-proxy =
    let
      acmeDescription = "The name used for the security.acme.certs.<name> properity.";
    in
    {
      defaults = {
        acmeCertName = lib.mkOption {
          description = acmeDescription;
        };
      };

      virtualHosts = lib.mkOption {
        description = "Virtual hosts served by the reverse-proxy.";
        default = { };

        type = types.attrsOf (
          types.submodule (
            { ... }:
            {
              options = {
                port = lib.mkOption {
                  description = "On which port the service is listening.";
                  type = types.ints.between 0 65535;
                };

                containerName = lib.mkOption {
                  description = "Name of the container running the virtual host.";
                  type = types.str;
                };

                acmeCertName = lib.mkOption {
                  description = acmeDescription;
                  type = types.nullOr types.str;
                };
              };

              config = {
                acmeCertName = lib.mkDefault cfg.defaults.acmeCertName;
              };
            }
          )
        );
      };
    };

  config = lib.mkIf (builtins.length containerNames != 0) {
    server.containerNames = [ containerName ] ++ containerNames;
    systemd.network = {
      enable = true;
      netdevs."25-${bridgeName}" = {
        netdevConfig = {
          Kind = "bridge";
          Name = bridgeName;
        };
      };

      networks."45-${bridgeName}" = {
        matchConfig.Name = bridgeName;
        networkConfig.ConfigureWithoutCarrier = true;
      };
    };

    # See https://nixos.org/manual/nixos/stable/#module-security-acme-root-owned
    security.acme.certs = lib.genAttrs uniqueCerts (cert: {
      postRun = "systemctl restart container@${containerName};";
    });
    systemd.services."container@${containerName}".serviceConfig.LoadCredential = map (
      cert:
      let
        certDir = config.security.acme.certs.${cert}.directory;
      in
      "${cert}.pem:${certDir}/full.pem"
    ) uniqueCerts;

    containers = {
      ${containerName} =
        let
          certDir = "/run/credentials/acme";
        in
        {
          extraVeths.${veth}.hostBridge = bridgeName;

          bindMounts = lib.pipe cfg.virtualHosts [
            builtins.attrNames
            (
              domains:
              lib.genAttrs domains (
                domain: with cfg.virtualHosts.${domain}; {
                  # Cannot use environment variable $CREDENTIALS_DIRECTORY :c
                  hostPath = "/run/credentials/container@${containerName}.service/${acmeCertName}.pem";
                  mountPoint = "${certDir}/${domain}.pem:owneridmap";
                  isReadOnly = true;
                }
              )
            )
          ];

          config = {
            environment.systemPackages = with pkgs; [ dnsutils ];
            boot.kernel.sysctl = {
              "net.ipv6.conf.all.forwarding" = 2;
            };

            services.resolved.settings.Resolve.MulticastDNS = "resolve";
            systemd.network = {
              enable = true;
              networks."40-${veth}" = {
                matchConfig.Name = veth;

                address = [ "${ulaPrefix}::1/64" ];
                ipv6Prefixes = [ { Prefix = "${ulaPrefix}::/64"; } ];
                networkConfig = {
                  IPv6SendRA = true;
                  IPv6AcceptRA = false;
                  MulticastDNS = "resolve";
                };
              };
            };

            # NAT66 for the HTTP network
            # Provides internet access without assigning public IPv6 addresses
            networking.nftables = {
              enable = true;
              ruleset = ''
                table ip6 nat {
                  chain postrouting {
                    type nat hook postrouting priority srcnat; policy accept;
                    iifname "${veth}" oifname "eth0" masquerade
                  }
                }
              '';
            };

            # mDNS
            networking.firewall.interfaces.${veth}.allowedUDPPorts = [ 5353 ];
            networking.firewall.allowedTCPPorts = [
              80 # HTTP
              443 # HTTPS
            ];

            systemd.services.haproxy.serviceConfig.LoadCredential = lib.pipe cfg.virtualHosts [
              builtins.attrNames
              (map (domain: "${domain}.pem:${certDir}/${domain}.pem"))
            ];

            services.haproxy.enable = true;
            services.haproxy.config = ''
              resolvers sys
                parse-resolv-conf
              frontend www
                mode http
                bind :::80
                bind :::443 ssl crt /run/credentials/haproxy.service/ # $CREDENTIALS_DIRECTORY hard-coded
                http-request redirect scheme https unless { ssl_fc }
                use_backend %[req.hdr(Host),lower]
            ''
            + lib.pipe cfg.virtualHosts [
              (lib.mapAttrsToList (
                domain: cfgHost:
                let
                  serverName = "container_${cfgHost.containerName}";
                  origin = "${cfgHost.containerName}.local:${toString cfgHost.port}";
                in
                # Delay initial DNS query
                # Increases the change that mDNS has already resolved correctly
                # Minimises initial delay
                ''
                  backend ${domain}
                    mode http
                    server ${serverName} ${origin} resolvers sys init-addr last,none
                ''
              ))
              (lib.concatStringsSep "\n\n")
            ];
          };
        };
    }
    // lib.genAttrs containerNames (name: {
      hostBridge = bridgeName;
      config = {
        networking.firewall.allowedUDPPorts = [ 5353 ];
        services.resolved.settings.Resolve.MulticastDNS = true;

        systemd.network = {
          enable = true;
          networks."20-mDNS" = {
            matchConfig.Name = "eth*";
            networkConfig.MulticastDNS = true;
          };
        };
      };
    });
  };
}
