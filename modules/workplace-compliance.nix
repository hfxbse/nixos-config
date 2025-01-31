{ config, lib, pkgs, ... }:
let
  cfg = config.workplaceCompliance;
  types = lib.types;
in {
  options.workplaceCompliance = {
    enable = lib.mkEnableOption "workplace compliance";

    av.enable = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable an anti-virus";
    };

    firewall.enable = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable a firewall";
    };

    ikev2.enable = lib.mkEnableOption "IKEv2 VPN connection support";
  };

  config = lib.mkIf cfg.enable {
    services.clamav = {
      updater.enable = cfg.av.enable;
      daemon.enable = cfg.av.enable;
    };

    networking.networkmanager.enableStrongSwan = lib.mkDefault cfg.ikev2.enable;

    networking.firewall = {
      enable = cfg.firewall.enable;
      checkReversePath = lib.mkIf (
        cfg.ikev2.enable ||
        config.networking.networkmanager.enableStrongSwan
      ) "loose";
    };
  };
}
