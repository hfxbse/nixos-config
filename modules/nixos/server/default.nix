{ config, lib, ... }:
let
  cfg = config.server;
in
{
  imports = [
    ./immich.nix
  ];

  options.server.enable = lib.mkEnableOption "server container support with systemd-nspawn";
  options.server.externalNetworkInterface = lib.mkOption {
    description = "External network used for the NAT";
    type = lib.types.nullOr lib.types.str;
  };

  options.server.hostAddressSubnet = lib.mkOption {
    description = "Host address subnet prefix to assign to the container host interface";
    type = lib.types.str;
    default = "10.42.111";
  };

  config = lib.mkIf cfg.enable {
    networking.nat = {
      enable = true;
      externalInterface = cfg.externalNetworkInterface;
      internalInterfaces = [ "ve-+" ];
    };
  };
}
