{ config, lib, ... }:
let
  cfg = config.server.router // {
    enable = lib.pipe config.server.services [
      builtins.attrValues
      (lib.any (server: server.enable or false))
    ];
  };

  types = lib.types;
  bridgeName = "br-ve";
in
{
  options.server.router.wan = lib.mkOption {
    description = "Upstream internet interface";
    type = types.types.str;
  };

  config = lib.mkIf cfg.enable {
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
    };

    server.containerNames = [ "router" ];
    containers = {
      router = {
        privateNetwork = true;
        macvlans = [ cfg.wan ];
        hostBridge = bridgeName;

        config = {
          networking.hostName = "${config.networking.hostName}-router";
          systemd.network = {
            enable = true;
            networks."10-wan" = {
              matchConfig.Name = "mv-${cfg.wan}";
              networkConfig.DHCP = "yes";
            };
          };

          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          networking.useHostResolvConf = lib.mkForce false;
          services.resolved.enable = lib.mkDefault true;
        };
      };
    }
    // lib.pipe config.server.containerNames [
      (builtins.filter (name: name != "router"))
      (
        names:
        lib.genAttrs names (name: {
          inherit (config.containers.router) privateNetwork hostBridge;
        })
      )
    ];
  };
}
