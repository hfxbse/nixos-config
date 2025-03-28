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
    environment.etc."strongswan.conf" = lib.mkIf cfg.ikev2.enable {
      # See https://github.com/NixOS/nixpkgs/issues/375352#issue-2800029311
      text = "";
    };

    networking.firewall = {
      enable = cfg.firewall.enable;
      checkReversePath = lib.mkIf (
        cfg.ikev2.enable ||
        config.networking.networkmanager.enableStrongSwan
      ) "loose";
    };
  };
}
