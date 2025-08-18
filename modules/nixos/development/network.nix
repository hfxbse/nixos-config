{ config, lib, ... }:
let
  cfg = config.development.network;
in
{
  options.development.network.enable = lib.mkEnableOption "tools helpful for network setups";

  config.services.iperf3 = lib.mkIf cfg.enable {
    enable = true;
    openFirewall = true;
    bind = "0.0.0.0";
  };
}
