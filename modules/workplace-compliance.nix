{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workplaceCompliance;
  types = lib.types;
in
{
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

  config =
    let
      strongswan = pkgs.networkmanager-strongswan;
    in
    lib.mkIf cfg.enable {
      services.clamav = {
        updater.enable = cfg.av.enable;
        daemon.enable = cfg.av.enable;
      };

      networking.networkmanager.plugins = lib.optional cfg.ikev2.enable strongswan;
      environment.etc = lib.mkIf cfg.ikev2.enable {
        # See https://github.com/NixOS/nixpkgs/issues/375352#issue-2800029311
        "strongswan.conf".text = "";
      };

      networking.firewall =
        let
          strongswan-enabled = builtins.elem strongswan config.networking.networkmanager.plugins;
        in
        {
          enable = cfg.firewall.enable;
          checkReversePath = lib.mkIf strongswan-enabled "loose";
        };
    };
}
