{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.router // {
    enable = lib.pipe config.server.services [
      builtins.attrValues
      (lib.any (server: server.enable or false))
    ];
  };

  resolverFix = {
    # Use systemd-resolved inside the containers
    # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
    networking.useHostResolvConf = lib.mkForce false;
    services.resolved.enable = lib.mkDefault true;
  };

  types = lib.types;
  bridgeName = "br-ve";
  ulaPrefix = "fd7e:f08c:27e1";
in
{
  options.server.router.wan = lib.mkOption {
    description = "Upstream internet interface";
    type = types.types.str;
  };

  config = lib.mkIf cfg.enable {
    virtualisation.vmVariant = {
      # By default deprecated side-local addresses are chosen by QEMU
      # When setting an ULA, internet connectivity breaks because of this
      # Forcing QEMU to use an ULA as well fixes this.
      virtualisation.qemu.networkingOptions = lib.mkForce [
        "-net nic,netdev=user.0,model=virtio"
        "-netdev user,id=user.0,ipv6-prefix=${ulaPrefix}:0::,ipv6-prefixlen=64,\"$QEMU_NET_OPTS\""
      ];

      # Enable NAT66 when running as VM as their ain't any global IPv6 address
      containers.router.config.networking.nftables.ruleset = ''
        table ip6 nat {
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            iifname "eth0" oifname "mv-${cfg.wan}" masquerade
          }
        }
      '';
    };

    networking.firewall.enable = true;
    networking.nftables.enable = true;

    systemd.network = {
      enable = true;
      netdevs."21-${bridgeName}" = {
        netdevConfig = {
          Kind = "bridge";
          Name = bridgeName;
        };
      };

      networks."41-${bridgeName}" = {
        matchConfig.Name = bridgeName;
        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6AcceptRA = false;
        };
      };
    };

    server.containerNames = [ "router" ];
    containers = {
      router = {
        privateNetwork = true;
        macvlans = [ cfg.wan ];
        hostBridge = bridgeName;

        config = lib.recursiveUpdate resolverFix {
          boot.kernel.sysctl = {
            "net.ipv6.conf.all.forwarding" = 2;
          };

          networking.hostName = "${config.networking.hostName}-router";
          networking.nftables.enable = true;

          systemd.network = {
            enable = true;
            networks = {
              "10-wan" = {
                matchConfig.Name = "mv-${cfg.wan}";
                networkConfig = {
                  DHCP = true;
                  IPv6AcceptRA = true;
                };
              };

              "30-${bridgeName}" = {
                address = [ "${ulaPrefix}:1::1/64" ];
                matchConfig.Name = "eth*";
                networkConfig = {
                  DHCPPrefixDelegation = true;
                  IPv6SendRA = true;
                  IPv6AcceptRA = false;
                };
                ipv6Prefixes = [ { Prefix = "${ulaPrefix}:1::/64"; } ];
              };
            };
          };
        };
      };
    }
    // lib.pipe config.server.containerNames [
      (builtins.filter (name: name != "router"))
      (
        names:
        lib.genAttrs names (name: {
          inherit (config.containers.router) privateNetwork hostBridge;
          config = lib.recursiveUpdate resolverFix {
            environment.systemPackages = with pkgs; [ traceroute ];
            systemd.network = {
              enable = true;
              networks."30-${bridgeName}" = {
                matchConfig.Name = "eth*";
                networkConfig.DHCP = true;
              };
            };
          };
        })
      )
    ];
  };
}
