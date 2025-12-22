{
  config,
  lib,
  ...
}:
let
  cfg = config.server.smart-home;
in
{
  imports = [ ./mqtt.nix ];

  options.server.smart-home = {
    enable = lib.mkEnableOption "a smart home integration with in a container";

    systemStateVersion = lib.mkOption {
      description = "System state version used for the container. Do not change it after the container has been created.";
      type = lib.types.str;
      default = config.system.stateVersion;
    };
  };

  config = lib.mkIf (config.server.enable && cfg.enable) {
    server = {
      network.smart-home = {
        subnetPrefix = "10.0.249";
        internetAccess = true;
      };
    };

    containers.smart-home = {
      autoStart = true;
      privateUsers = "pick";

      config = {
        system.stateVersion = cfg.systemStateVersion;
      };
    };
  };
}
