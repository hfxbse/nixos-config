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
    description = "External network interface used for the NAT";
    type = lib.types.nullOr lib.types.str;
  };

  config = lib.mkIf cfg.enable {
    networking.nat = {
      enable = true;
      externalInterface = cfg.externalNetworkInterface;
      internalInterfaces = [ "ve-+" ];
    };
  };
}
