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

  lanVb = "vb-rp-lan";
  wanVb = "vb-rp-wan";
  veth = "vb-http";

  portNumber = types.ints.between 0 65535;

  containerNames = lib.pipe cfg.virtualHosts [
    builtins.attrValues
    (map ({ containerName, ... }: containerName))
  ];
in
{
  options.server.services.reverse-proxy =
    let
      acmeDescription = "The name used for the security.acme.certs.<name> properity.";
    in
    {
      ports = {
        http = lib.mkOption {
          description = "On which port to listen for HTTP trafic";
          type = portNumber;
          default = 80;
        };

        https = lib.mkOption {
          description = "On which port to listen for HTTPS trafic";
          type = portNumber;
          default = 443;
        };
      };

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
                  type = portNumber;
                };

                containerName = lib.mkOption {
                  description = "Name of the container running the virtual host.";
                  type = types.str;
                };

                acmeCertName = lib.mkOption {
                  description = acmeDescription;
                  type = types.str;
                  default = cfg.defaults.acmeCertName;
                };

                public = lib.mkEnableOption {
                  description = "Allow access from the public internet.";
                };
              };
            }
          )
        );
      };
    };

  config = lib.mkIf (builtins.length containerNames != 0) {
    security.acme.certs = lib.pipe cfg.virtualHosts [
      builtins.attrValues
      (map ({ acmeCertName, ... }: acmeCertName))
      lib.unique
      (lib.flip lib.genAttrs (cert: {
        # See https://nixos.org/manual/nixos/stable/#module-security-acme-root-owned
        postRun = "systemctl restart container@${containerName};";
      }))
    ];

    server = {
      containers = lib.genAttrs containerNames (_: { }) // {
        ${containerName}.secrets = lib.flip builtins.mapAttrs cfg.virtualHosts (
          domain: host: {
            name = "acme/${domain}.pem";
            path = "${config.security.acme.certs.${host.acmeCertName}.directory}/full.pem";
          }
        );
      };

      ingress.forwardPorts = lib.pipe cfg.ports [
        builtins.attrValues
        (map (port: {
          inherit containerName port;
          protocol = "tcp";
        }))
      ];
    };

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

    containers = {
      ${containerName} = {
        hostBridge = null;
        extraVeths = with config.server.ingress; {
          ${lanVb}.hostBridge = bridgeNames.lan;
          ${wanVb}.hostBridge = bridgeNames.wan;
          ${veth}.hostBridge = bridgeName;
        };

        config = {
          services.avahi.allowInterfaces = lib.mkForce [ lanVb ];

          environment.systemPackages = with pkgs; [ dnsutils ];
          boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;

          services.resolved.settings.Resolve.MulticastDNS = "resolve";
          networking.firewall = {
            checkReversePath = "loose";
            interfaces = lib.genAttrs [ veth lanVb ] (_: {
              allowedUDPPorts = [ 5353 ]; # mDNS
            });
          };

          systemd.network = {
            enable = true;
            networks =
              let
                vbNet = interface: {
                  "30-${interface}" = {
                    matchConfig.Name = interface;
                    networkConfig = {
                      IPv6SendRA = false;
                      IPv6AcceptRA = true;
                      IPv6Forwarding = true;
                    };
                  };
                };
              in
              vbNet lanVb
              // vbNet wanVb
              // {
                "40-${veth}" = {
                  matchConfig.Name = veth;

                  address = [ "${ulaPrefix}::1/64" ];
                  ipv6Prefixes = [ { Prefix = "${ulaPrefix}::/64"; } ];
                  networkConfig = {
                    IPv6SendRA = true;
                    IPv6AcceptRA = false;
                    IPv6Forwarding = true;
                    MulticastDNS = "resolve";
                  };
                };
              };
          };

          # NAT66 for the HTTP network
          # Provides internet access without assigning public IPv6 addresses
          networking.nftables = {
            enable = true;
            tables = {
              nat = {
                family = "ip6";
                content = ''
                  chain postrouting {
                    type nat hook postrouting priority srcnat; policy accept;
                    iifname "${veth}" oifname { "${lanVb}", "${wanVb}" } masquerade
                  }
                '';
              };
              http-isolation = {
                family = "inet";
                content = ''
                  chain forward {
                    type filter hook forward priority 0; policy accept;
                    ct state established,related accept
                    iifname { "${lanVb}", "${wanVb}" } oifname ${veth} drop;
                    iifname "${veth}" fib daddr oifname "${lanVb}" drop;
                  }
                '';
              };
            };
          };

          networking.firewall.allowedTCPPorts = builtins.attrValues cfg.ports;

          systemd.services.haproxy.serviceConfig.LoadCredential = lib.pipe cfg.virtualHosts [
            builtins.attrNames
            (map (domain: "${domain}.pem:/run/credentials/acme/${domain}.pem"))
          ];

          services.haproxy.enable = true;
          services.haproxy.config =
            with cfg.ports;
            let
              # $CREDENTIALS_DIRECTORY has to be hard-coded :c
              frontend = label: interface: ''
                frontend ${label}
                  bind :::${toString http} interface ${interface}
                  bind :::${toString https} interface ${interface} ssl crt /run/credentials/haproxy.service/
                  http-request redirect scheme https unless { ssl_fc }
                  use_backend %[req.hdr(Host),lower,word(1,:)]_${label}
              '';
            in
            ''
              global
                maxconn 10000
              defaults
                mode http
                option forwarded
                option forwardfor
                compression algo gzip
                timeout connect 10s
                timeout client 60s
                timeout server 60s
                timeout tunnel 1h
              resolvers sys
                parse-resolv-conf
            ''
            + frontend "lan" lanVb
            + frontend "wan" wanVb
            + lib.pipe cfg.virtualHosts [
              (lib.mapAttrsToList (
                domain: cfgHost:
                let
                  serverName = "container_${cfgHost.containerName}";
                  origin = "${cfgHost.containerName}.local:${toString cfgHost.port}";

                  # Do not use libc to initialize the server IPs
                  # Libc will most likely try to resolve the DNS names before mDNS
                  # fully up and running.
                  # This is not only bad for the start up time, but also messes up
                  # routing for the HTTP services and therefore internet access
                  backend = label: ''
                    backend ${domain}_${label}
                      compression offload
                      server ${serverName} ${origin} resolvers sys init-addr last,none
                  '';
                in
                backend "lan" + lib.optionalString cfgHost.public (backend "wan")
              ))
              lib.concatStrings
            ];
        };
      };
    }
    // lib.genAttrs containerNames (name: {
      hostBridge = bridgeName;
      config = {
        services.avahi = {
          allowInterfaces = [ "eth0" ];
          enable = true;
          ipv4 = false;
          publish = {
            enable = true;
            addresses = true;
          };
        };
      };
    });

    virtualisation.vmVariant.containers.${containerName}.config = {
      # Networking breakes without GUA
      # Ignore WAN interface for routing, everything has to go in via
      # a local IPv4 anyways because of QEMUs limitations
      networking.nftables.tables.http-isolation.enable = false;
      systemd.network = {
        networks."30-${wanVb}".networkConfig.VRF = "vrf-wan";
        netdevs."10-vrf-wan" = {
          netdevConfig = {
            Name = "vrf-wan";
            Kind = "vrf";
          };
          vrfConfig.Table = 2000;
        };
      };
    };
  };
}
