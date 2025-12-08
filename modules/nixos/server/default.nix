{ config, lib, ... }:
let
  cfg = config.server;
in
{
  imports = [
    ./dns.nix
    ./immich.nix
    ./oidc.nix
    ./reverse-proxy.nix
  ];

  options.server = {
    enable = lib.mkEnableOption "server container support with systemd-nspawn";
    externalNetworkInterface = lib.mkOption {
      description = "External network interface used for the NAT";
      type = lib.types.nullOr lib.types.str;
    };

    stateDirectories = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.listOf lib.types.path);
    };

    network = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
          {
            options = {
              subnetPrefix = lib.mkOption {
                type = lib.types.strMatching "([0-9]{1,3}.){2}[0-9]{1,3}";
                example = "10.0.255";
              };

              forwardPorts = lib.mkOption {
                default = [ ];
                type = lib.types.listOf (
                  lib.types.submodule (
                    { ... }:
                    {
                      options = {
                        external = lib.mkEnableOption "exposing the port on the external networking interface of the host";
                        port = lib.mkOption {
                          description = "Port number";
                          type = lib.types.ints.positive;
                        };

                        allowVNets = lib.mkOption {
                          description = "Which VNet IP ranges to accept incoming traffic from. Connection from host's LAN are allowed by default.";
                          type = lib.types.listOf lib.types.str;
                          default = [ ];
                        };

                        vmHostPort = lib.mkOption {
                          description = ''
                            Port number the port gets mapped to on the host machine when running as the vm variant.
                            Defaults to the same port used inside the guest machine.
                          '';
                          type = lib.types.nullOr lib.types.ints.positive;
                          default = null;
                        };

                        protocols = lib.mkOption {
                          type = lib.types.listOf (
                            lib.types.enum [
                              "tcp"
                              "udp"
                            ]
                          );
                          description = "Which protocols to allow";
                          default = [ "tcp" ];
                        };
                      };
                    }
                  )
                );
              };
            };
          }
        )
      );
    };
  };

  config =
    let
      forwardPorts = builtins.concatMap (
        containerName:
        builtins.map (
          forwardPort: forwardPort // { inherit containerName; }
        ) cfg.network.${containerName}.forwardPorts
      ) (builtins.attrNames cfg.network);
      externallyExposedPorts = builtins.filter (port: port.external) forwardPorts;

      allowedPorts =
        protocol: forwardPorts:
        builtins.map ({ port, ... }: port) (
          builtins.filter ({ protocols, ... }: builtins.elem protocol protocols) forwardPorts
        );
    in
    lib.mkIf cfg.enable {
      networking.nat = {
        enable = true;
        externalInterface = cfg.externalNetworkInterface;
        internalInterfaces = [ "ve-+" ];
      };

      networking.firewall = {
        allowedTCPPorts = allowedPorts "tcp" externallyExposedPorts;
        allowedUDPPorts = allowedPorts "udp" externallyExposedPorts;

        extraCommands =
          let
            rulePrio = protocol: builtins.toString (if protocol == "tcp" then 1 else 2);
            rule =
              {
                protocol,
                source,
                destination,
                port,
                ...
              }:
              "iptables -I FORWARD ${rulePrio protocol} -s ${source} -d ${destination} -p ${protocol} --dport ${builtins.toString port} -j ACCEPT";

            rules =
              {
                port,
                protocols,
                allowVNets,
                virtualHostName,
                ...
              }:
              builtins.concatMap (
                vnet:
                builtins.map (
                  protocol:
                  rule {
                    inherit protocol port;
                    source = "${cfg.network.${vnet}.subnetPrefix}.0/24";
                    destination = "${cfg.network.${virtualHostName}.subnetPrefix}.0/24";
                  }
                ) protocols
              ) allowVNets;

            vnetConnections = builtins.concatMap (
              virtualHostName:
              (builtins.concatMap (
                forwardPort: rules (forwardPort // { inherit virtualHostName; })
              ) cfg.network.${virtualHostName}.forwardPorts)
            ) (builtins.attrNames cfg.network);
          in
          ''
            # Block connections from VNets to host
            iptables -A INPUT -s 10.0.0.0/8 -j DROP

            # Allow the local network to reach the containers but not in reverse
            iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
            iptables -A FORWARD -s 10.0.0.0/8 -d 192.168.0.0/16 -m conntrack --ctstate NEW -j DROP
            iptables -A FORWARD -s 192.168.0.0/16 -d 10.0.0.0/8 -j ACCEPT

            ip6tables -A FORWARD -s fe80::/10 -d 2001:9e8:2e07:f00::/64 -m conntrack --ctstate NEW -j DROP
            ip6tables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

            # Block all traffic between VNets by default
            iptables -A FORWARD -s 10.0.0.0/8 -d 10.0.0.0/8 -j DROP

            # Allow specific VNet connections
            ${lib.concatStringsSep "\n" vnetConnections}
          '';
      };

      virtualisation.vmVariant.virtualisation.forwardPorts = builtins.concatMap (
        {
          port,
          vmHostPort,
          protocols,
          ...
        }:
        builtins.map (protocol: {
          from = "host";
          host.port = if vmHostPort != null then vmHostPort else port;
          guest.port = port;
          proto = protocol;
        }) protocols
      ) externallyExposedPorts;

      networking.nat.forwardPorts = builtins.concatMap (
        {
          port,
          protocols,
          containerName,
          ...
        }:
        builtins.map (protocol: {
          sourcePort = port;
          proto = protocol;
          destination = "${config.containers.${containerName}.localAddress}:${builtins.toString port}";
        }) protocols
      ) externallyExposedPorts;

      systemd.services =
        let
          services = builtins.map (name: "container@${name}") (builtins.attrNames cfg.stateDirectories);
        in
        lib.genAttrs services (service: {
          serviceConfig = {
            StateDirectory =
              let
                directories = cfg.stateDirectories.${lib.removePrefix "container@" service};
              in
              builtins.map (directory: lib.removePrefix "/var/lib/" directory) directories;
          };
        });

      containers = lib.genAttrs (lib.attrNames cfg.network) (
        name:
        let
          cfgNetwork = cfg.network.${name};
        in
        {
          privateNetwork = cfgNetwork.subnetPrefix != null;
          hostAddress = "${cfgNetwork.subnetPrefix}.1";
          localAddress = "${cfgNetwork.subnetPrefix}.2";

          config = {
            # Use systemd-resolved inside the container
            # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
            networking.useHostResolvConf = lib.mkForce false;
            services.resolved.enable = lib.mkDefault true;

            networking.firewall = {
              enable = true;
              allowedTCPPorts = allowedPorts "tcp" cfgNetwork.forwardPorts;
              allowedUDPPorts = allowedPorts "udp" cfgNetwork.forwardPorts;
            };
          };
        }
      );
    };
}
