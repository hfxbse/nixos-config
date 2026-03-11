{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.development.network;
in
{
  options.development.network = {
    enable = lib.mkEnableOption "tools helpful for network setups";

    role = lib.mkOption {
      description = "Role \"server\" activates service listeners.";
      default = "client";
      type = types.enum [
        "client"
        "server"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.iperf3 = lib.mkIf (cfg.role == "server") {
      enable = true;
      openFirewall = true;
      bind = "0.0.0.0";
    };

    users.users.${config.user.name}.packages = with pkgs; [
      dnsutils
      docker-compose
      iperf3
      nmap
      tcpdump
      traceroute
    ];
  };
}
