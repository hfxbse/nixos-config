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
      default = {};
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

      networking.firewall.allowedTCPPorts = allowedPorts "tcp" externallyExposedPorts;
      networking.firewall.allowedUDPPorts = allowedPorts "udp" externallyExposedPorts;

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
