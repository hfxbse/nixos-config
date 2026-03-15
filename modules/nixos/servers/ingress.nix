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
  ingressName = "mv-ingress";
  lanName = "vb-lan";
  wanName = "vb-wan";

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

    gatewayLLA = lib.mkOption {
      description = "LLA address of the gateway connected to the WAN interface";
      type = types.str;
    };

    bridgeNames = {
      wan = lib.mkOption {
        description = "Name of the host bridge receiving ingress from WAN";
        type = types.str;
        default = "br-wan";
      };

      lan = lib.mkOption {
        description = "Name of the host bridge receiving ingress from WAN";
        type = types.str;
        default = "br-lan";
      };
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
    networking.firewall.enable = true;
    networking.nftables.enable = true;

    systemd.network = with cfg.bridgeNames; {
      enable = true;
      netdevs =
        let
          netDev = bridgeName: {
            "21-${bridgeName}" = {
              netdevConfig = {
                Kind = "bridge";
                Name = bridgeName;
              };
            };
          };
        in
        (netDev wan) // (netDev lan);

      networks."41-br-ingress" = {
        matchConfig.Name = [
          lan
          wan
        ];

        networkConfig = {
          ConfigureWithoutCarrier = true;
          IPv6AcceptRA = false;
        };
        linkConfig.RequiredForOnline = "carrier";
      };
    };

    server.containers.ingress = { };
    containers = {
      ingress = {
        privateNetwork = true;
        # Use single macvlan as the Fritz!Box sucks ass and will always
        # send all traffic to the interface soliciting the RA breaking
        # the reverse-path check / routing when separate macvlan interfaces
        # are used for WAN and LAN incoming traffic.
        # LAN only services have to be accessed via port forwarding.
        macvlans = [ "${cfg.wan}:${ingressName}" ];
        extraVeths = {
          ${lanName}.hostBridge = cfg.bridgeNames.lan;
          ${wanName}.hostBridge = cfg.bridgeNames.wan;
        };

        config = lib.recursiveUpdate resolverFix {
          boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
          networking.firewall.checkReversePath = "loose";
          networking.nftables = {
            enable = true;
            tables = {
              dmz = {
                # Prevent access to devices on the LAN
                family = "ip6";
                content = ''
                  chain forward {
                    type filter hook forward priority filter; policy accept;
                    ct state established,related accept
                    oifname "${ingressName}" rt nexthop != ${cfg.gatewayLLA} drop;
                  }
                '';
              };
              lan-isolation = {
                family = "inet";
                content = ''
                  chain forward {
                    type filter hook forward priority 0; policy accept;
                    ct state established,related accept
                    iifname "${ingressName}" oifname { "${lanName}" } drop;
                    iifname "${wanName}" oifname { "${lanName}" } drop;
                  }
                '';
              };
            };
          };

          environment.systemPackages = with pkgs; [ dig ];

          systemd.network = {
            enable = true;
            networks =
              let
                vbNet =
                  label:
                  {
                    ula,
                    mDNS ? false,
                  }:
                  {
                    "30-vb-${label}" = {
                      address = [ "${ula}::1/64" ];
                      matchConfig.Name = "vb-${label}";
                      ipv6Prefixes = [ { Prefix = "${ula}::/64"; } ];

                      networkConfig = {
                        DHCPPrefixDelegation = true;
                        IPv6SendRA = true;
                        IPv6AcceptRA = false;
                        IPv6Forwarding = true;
                        MulticastDNS = lib.mkIf mDNS "resolve";
                      };
                    };
                  };
              in
              {
                "20-${ingressName}" = rec {
                  matchConfig.Name = ingressName;
                  networkConfig = {
                    DHCP = true;
                    IPv6AcceptRA = true;
                    IPv6Forwarding = true;
                    # SOCAT will use the private IPv6 unless disabled
                    IPv6PrivacyExtensions = false;
                  };

                  dhcpV4Config.Hostname = "${config.networking.hostName}-ingress";
                  # Only use DHCPv6 for prefix delegation.
                  # Assign own address via SLAAC.
                  dhcpV6Config = {
                    inherit (dhcpV4Config) Hostname;
                    WithoutRA = "solicit";
                    UseAddress = false;
                  };
                };

              }
              // (vbNet "wan" { ula = "fd51:1757:d0ce:320e"; })
              // (vbNet "lan" {
                ula = "fd9e:adea:e09c:9707";
                mDNS = true;
              });
          };

          services.resolved.settings.Resolve.MulticastDNS = lib.mkIf useForwarding "resolve";
          networking.firewall.interfaces = lib.mkIf useForwarding (
            lib.genAttrs [ lanName wanName ] (interface: {
              allowedUDPPorts = [ 5353 ]; # mDNS
            })
            // lib.genAttrs [ ingressName ] (_: {
              allowedUDPPorts = allowedPorts "udp";
              allowedTCPPorts = allowedPorts "tcp";
            })
          );

          services.resolved.settings.Resolve.DNSStubListener = false;
          boot.kernel.sysctl."net.ipv6.bindv6only" = false;
          systemd.services = {
            systemd-networkd.serviceConfig = {
              # Easier debugging of DHCPv6
              Environment = "SYSTEMD_LOG_LEVEL=debug";
            };
          }
          // lib.pipe cfg.forwardPorts [
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
                    # TCP6/UDP4 listens for both IPv4 and IPv6 as
                    # /proc/sys/net/ipv6/bindv6only is turned off
                    if protocol == "tcp" then
                      [
                        (lib.getExe pkgs.socat)
                        "-d -T 60"
                        "TCP6-LISTEN:${toString port},fork,reuseaddr"
                        "TCP6:${target}"
                      ]
                    else
                      [
                        (lib.getExe pkgs.socat)
                        "-d -T 20"
                        "UDP6-RECVFROM:${toString port},fork,reuseaddr"
                        "UDP6-SENDTO:${target}"
                      ]
                  );

                  serviceConfig = rec {
                    Restart = "always";
                    AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
                    # Hardening
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
    // lib.pipe config.server.containers [
      builtins.attrNames
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
            hostBridge = lib.mkDefault cfg.bridgeNames.lan;

            config = lib.recursiveUpdate resolverFix {
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
                networks."30-${cfg.bridgeNames.lan}" = {
                  matchConfig.Name = "eth0";
                  networkConfig.DHCP = true;
                };
              };
            };
          }
        )
      )
    ];

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
            "-netdev user,id=user.0,${forwardingOptions},ipv6-prefix=fd00:2e57:eb00:74df::,ipv6-prefixlen=64,\${QEMU_NET_OPTS:+,$QEMU_NET_OPTS}"
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
      boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
      containers.ingress.config.networking.nftables.tables = {
        dmz.enable = false;
        lan-isolation.enable = false;
        nat = {
          family = "ip6";
          content = ''
            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;
              iifname "${lanName}" oifname "${ingressName}" masquerade
            }
          '';
        };
      };
    };
  };
}
