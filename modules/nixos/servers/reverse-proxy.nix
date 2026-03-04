{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;

  cfg = config.server.services.reverse-proxy;
  bridgeName = "br-http";
  ulaPrefix = "fd00:9d1f:b7b7:1721";
  veth = "vb-http";

  containerNames = lib.pipe cfg.virtualHosts [
    builtins.attrValues
    (map ({ containerName, ... }: containerName))
  ];
in
{
  options.server.services.reverse-proxy.virtualHosts = lib.mkOption {
    description = "Virtual hosts served the reverse-proxy";
    default = { };

    type = types.attrsOf (
      types.submodule (
        { ... }:
        {
          options = {
            port = lib.mkOption {
              description = "On which port the service is listening";
              type = types.ints.between 0 65535;
            };

            containerName = lib.mkOption {
              description = "Name of the container running the virtual host";
              type = types.str;
            };
          };
        }
      )
    );
  };

  config = lib.mkIf (builtins.length containerNames != 0) {
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

    server.containerNames = [ "reverse-proxy" ] ++ containerNames;
    containers = {
      reverse-proxy = {
        extraVeths.${veth}.hostBridge = bridgeName;

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

          services.haproxy.enable = true;
          services.haproxy.config = ''
            resolvers sys
              parse-resolv-conf
            frontend www
              mode http
              bind :::80
              use_backend %[req.hdr(Host),lower]
          ''
          + lib.pipe cfg.virtualHosts [
            (lib.mapAttrsToList (
              domain: cfgHost:
              let
                serverName = "container_${cfgHost.containerName}";
                origin = "${cfgHost.containerName}.local:${toString cfgHost.port}";
              in
              # Do not use the internel libc resolver of haproxy
              # The initial address resolution messes up mDNS completely
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
