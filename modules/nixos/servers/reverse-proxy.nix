{
  config,
  lib,
  ...
}:
let
  cfg = config.server.services.reverse-proxy;
  bridgeName = "br-http";
  ulaPrefix = "fd00:9d1f:b7b7:1721";
  veth = "vb-http";
in
{
  options.server.services.reverse-proxy.containerNames = lib.mkOption {
    description = "Names of the containers behind the reverse-proxy";
    default = [];
  };

  config = lib.mkIf (builtins.length cfg.containerNames != 0) {
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

    server.containerNames = [ "reverse-proxy" ] ++ cfg.containerNames;
    containers = {
      reverse-proxy = {
        extraVeths.${veth}.hostBridge = bridgeName;

        config = {
          boot.kernel.sysctl = {
            "net.ipv6.conf.all.forwarding" = 2;
          };

          systemd.network = {
            enable = true;
            networks."40-${veth}" = {
              matchConfig.Name = veth;

              address = [ "${ulaPrefix}::1/64" ];
              ipv6Prefixes = [ { Prefix = "${ulaPrefix}::/64"; } ];
              networkConfig = {
                IPv6SendRA = true;
                IPv6AcceptRA = false;
              };
            };
          };

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

          services.haproxy.enable = true;
          services.haproxy.config = "";
        };
      };
    }
    // lib.genAttrs cfg.containerNames (name: {
      hostBridge = bridgeName;
    });
  };
}
