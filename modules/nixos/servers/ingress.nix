{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.ingress // {
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

    services.resolved.settings.Resolve.LLMNR = "false";
  };

  types = lib.types;
  bridgeName = "br-ingress";
  ulaPrefix = "fd7e:f08c:27e1";

  useForwarding = builtins.length cfg.forwardPorts != 0;
  allowedPorts =
    protocol:
    lib.pipe cfg.forwardPorts [
      (builtins.filter (port: port.protocol == protocol))
      (map ({ port, ... }: port))
    ];
in
{
  options.server.ingress = {
    wan = lib.mkOption {
      description = "Upstream internet interface.";
      type = types.types.str;
    };

    forwardPorts = lib.mkOption {
      description = "Forwards TCP and UDP ports to containers when receiving an IPv4 package from LAN.";
      default = [ ];
      type = types.listOf (
        types.submodule (
          { ... }:
          {
            options = {
              port = lib.mkOption {
                description = "Port to forward.";
                type = types.ints.between 0 65535;
              };

              protocol = lib.mkOption {
                description = "Which protocol to forward";
                type = types.enum [
                  "tcp"
                  "udp"
                ];
              };

              containerName = lib.mkOption {
                description = "Name of the container to forward to.";
                type = types.str;
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.vmVariant = {
      virtualisation =
        let
          # Docs are lying, $QEMU_NET_OPTS is not set with the default values
          # Copying code snipped from nixpkgs but using lib.concatMapStringsSep not lib.concatMapStrings
          # See https://github.com/NixOS/nixpkgs/blob/fabb8c9deee281e50b1065002c9828f2cf7b2239/nixos/modules/virtualisation/qemu-vm.nix#L1247
          forwardingOptions = lib.concatMapStringsSep "," (
            {
              proto,
              from,
              host,
              guest,
            }:
            if from == "host" then
              "hostfwd=${proto}:${host.address}:${toString host.port}-"
              + "${guest.address}:${toString guest.port}"
            else
              "'guestfwd=${proto}:${guest.address}:${toString guest.port}-"
              + "cmd:${pkgs.netcat}/bin/nc ${host.address} ${toString host.port}'"
          ) config.virtualisation.vmVariant.virtualisation.forwardPorts;
        in
        {
          # By default deprecated side-local addresses are chosen by QEMU
          # When setting an ULA, internet connectivity breaks because of this
          # Forcing QEMU to use an ULA as well fixes this.
          qemu.networkingOptions = lib.mkForce [
            "-net nic,netdev=user.0,model=virtio"
            "-netdev user,id=user.0,${forwardingOptions},ipv6-prefix=${ulaPrefix}:0::,ipv6-prefixlen=64,\${QEMU_NET_OPTS:+,$QEMU_NET_OPTS}"
          ];

          forwardPorts = map (
            { port, protocol, ... }:
            {
              from = "host";
              host.port = port;
              guest = {
                inherit port;
                address = "10.0.2.16"; # macVlan interface
              };
              proto = protocol;
            }
          ) config.virtualisation.vmVariant.server.ingress.forwardPorts;
        };

      # Enable NAT66 when running as VM as their ain't any global IPv6 address
      containers.ingress.config.networking.nftables.ruleset = ''
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

    server.containerNames = [ "ingress" ];
    containers = {
      ingress = {
        privateNetwork = true;
        macvlans = [ cfg.wan ];
        hostBridge = bridgeName;

        config = lib.recursiveUpdate resolverFix {
          boot.kernel.sysctl = {
            "net.ipv6.conf.all.forwarding" = 2;
          };

          networking.hostName = "${config.networking.hostName}-ingress";
          networking.nftables.enable = true;

          environment.systemPackages = with pkgs; [ dig ];

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
                  MulticastDNS = lib.mkIf useForwarding "resolve";
                };
                ipv6Prefixes = [ { Prefix = "${ulaPrefix}:1::/64"; } ];
              };
            };
          };

          services.resolved.settings.Resolve.MulticastDNS = lib.mkIf useForwarding "resolve";
          networking.firewall.interfaces = lib.mkIf useForwarding {
            "eth0".allowedUDPPorts = [ 5353 ]; # mDNS
            "mv-${cfg.wan}" = {
              allowedUDPPorts = allowedPorts "udp";
              allowedTCPPorts = allowedPorts "tcp";
            };
          };

          systemd.services = lib.pipe cfg.forwardPorts [
            (map (
              {
                port,
                containerName,
                protocol,
                ...
              }:
              let
                target = "${containerName}.local:${toString port}";
              in
              {
                name = "forward@${protocol}_${toString port}";
                value = rec {
                  after = wants;
                  wants = [ "network-online.target" ];
                  wantedBy = [ "multi-user.target" ];
                  script = lib.concatStringsSep " " (
                    if protocol == "tcp" then
                      [
                        (lib.getExe pkgs.socat)
                        "-d -T 60"
                        "TCP4-LISTEN:${toString port},fork,reuseaddr"
                        "TCP6:${target}"
                      ]
                    else
                      [
                        (lib.getExe pkgs.socat)
                        "-d -T 20"
                        "UDP4-RECVFROM:${toString port},fork,reuseaddr"
                        "UDP6-SENDTO:${target}"
                      ]
                  );

                  serviceConfig = rec {
                    Restart = "always";
                    # Hardening
                    AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
                    CapabilityBoundingSet = AmbientCapabilities;
                    RestrictAddressFamilies = [
                      "AF_INET"
                      "AF_INET6"
                      "AF_UNIX"
                    ];
                    DynamicUser = true;
                    NoNewPrivileges = true;
                    MemoryMax = "128M";
                    TasksMax = 1000;
                    PrivateUsers = true;
                    PrivateTmp = true;
                    PrivateDevices = true;
                    PrivateMounts = true;
                    ProtectClock = true;
                    ProtectControlGroups = true;
                    ProtectHome = true;
                    ProtectHostname = true;
                    ProtectKernelLogs = true;
                    ProtectKernelModules = true;
                    ProtectKernelTunables = true;
                    ProtectSystem = "strict";
                    RestrictNamespaces = true;
                    RestrictRealtime = true;
                    RestrictSUIDSGID = true;
                    LockPersonality = true;
                  };
                };
              }
            ))
            builtins.listToAttrs
          ];
        };
      };
    }
    // lib.pipe config.server.containerNames [
      (builtins.filter (name: name != "ingress"))
      (
        names:
        lib.genAttrs names (
          name:
          let
            mDNS = builtins.any ({ containerName, ... }: name == containerName) cfg.forwardPorts;
          in
          {
            inherit (config.containers.ingress) privateNetwork;
            hostBridge = lib.mkDefault bridgeName;

            config = lib.recursiveUpdate resolverFix {
              environment.systemPackages = with pkgs; [
                dig
                traceroute
              ];

              networking.firewall.interfaces.eth0.allowedUDPPorts = lib.mkIf mDNS [ 5353 ]; # mDNS
              services.avahi = lib.mkIf mDNS {
                allowInterfaces = [ "eth0" ];
                enable = true;
                ipv4 = false;
                openFirewall = false;
                publish = {
                  enable = true;
                  addresses = true;
                };
              };

              systemd.network = {
                enable = true;
                networks."30-${bridgeName}" = {
                  matchConfig.Name = "eth0";
                  networkConfig.DHCP = true;
                };
              };
            };
          }
        )
      )
    ];
  };
}
