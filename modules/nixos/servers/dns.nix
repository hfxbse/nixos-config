{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  cfg = config.server.services.dns;

  capabilities = [ "CAP_NET_ADMIN" ];
in
{
  options.server.services.dns = {
    enable = lib.mkEnableOption {
      description = "A ad filtering recursive dns server services.";
    };

    port = lib.mkOption {
      description = "On which port the final DNS server is listening.";
      type = types.ints.between 0 65535;
      default = 53;
    };

    filterLists = lib.mkOption {
      description = "URLs to filter lists";
      type = types.listOf types.str;
      default = [ ];
    };

    fallbackDNS = lib.mkOption {
      description = "DNS servers to use if the internal recursive resolver fails.";
      default = { };
      type = types.attrsOf (
        types.submodule (
          { ... }:
          {
            options = {
              tls = lib.mkOption {
                description = "URL to use encrypted DNS over TLS";
                type = types.nullOr types.str;
                default = null;
              };

              ipAddresses = lib.mkOption {
                description = "IP addresses of the DNS server. If a TLS URL is provided, the addresses are used for bootstrapping.";
                type = types.listOf types.str;
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable rec {
    server = {
      containers.dns = { };
      ingress.forwardPorts = lib.flip map [ "tcp" "udp" ] (protocol: {
        inherit protocol;
        inherit (cfg) port;
        containerName = "dns";
      });
    };

    containers.dns.additionalCapabilities = capabilities;
    containers.dns.config =
      let
        inherit (containers.dns.config.services) unbound;
        unboundAddress = "[::1]:${toString unbound.settings.server.port}";
      in
      {
        services.resolved.enable = false;
        networking.firewall = {
          allowedTCPPorts = [ cfg.port ];
          allowedUDPPorts = [ cfg.port ];
        };

        systemd.services.blocky = rec {
          after = [ "unbound.service" ];
          requires = after;
        };

        services.blocky = {
          enable = true;
          settings = {
            connectIPVersion = "v6";
            ports.dns = cfg.port;
            upstreams = {
              init.strategy = "failOnError";
              strategy = "strict";
              groups.default = [
                unboundAddress
              ]
              ++ lib.pipe cfg.fallbackDNS [
                builtins.attrValues
                (lib.concatMap ({ tls, ipAddresses, ... }: if (tls != null) then [ tls ] else ipAddresses))
              ];
            };

            bootstrapDns = lib.pipe cfg.fallbackDNS [
              builtins.attrValues
              (builtins.filter ({ tls, ... }: tls != null))
              (map (
                { tls, ipAddresses, ... }:
                {
                  upstream = tls;
                  ips = ipAddresses;
                }
              ))
            ];

            blocking = {
              clientGroupsBlock.default = [ "default" ];
              denylists.default = cfg.filterLists;
            };
          };
        };

        systemd.services.unbound.serviceConfig = {
          AmbientCapabilities = capabilities;
          CapabilityBoundingSet = capabilities;
        };
        services.unbound = {
          enable = true;
          # Setting up a recursive resolver
          # See https://docs.pi-hole.net/guides/dns/unbound
          settings = {
            server = {
              interface = "::1";
              port = 5335;
              do-ip4 = true;
              do-udp = true;
              do-tcp = true;
              do-ip6 = true;
              prefer-ip6 = false;
              harden-glue = true;
              harden-dnssec-stripped = true;
              use-caps-for-id = false;
              edns-buffer-size = 1232;
              prefetch = true;
              num-threads = 1;
              so-rcvbuf = "1m";

              private-address = [
                # Ensure privacy of local IP ranges
                "192.168.0.0/16"
                "169.254.0.0/16"
                "172.16.0.0/12"
                "10.0.0.0/8"
                "fd00::/8"
                "fe80::/10"

                # Ensure no reverse queries to non-public IP ranges (RFC6303 4.2)
                "192.0.2.0/24"
                "198.51.100.0/24"
                "203.0.113.0/24"
                "255.255.255.255/32"
                "2001:db8::/32"
              ];
            };
          };
        };
      };
  };
}
