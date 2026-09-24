{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.single-user) username;
  cfg = config.single-user.home-manager;
in
{
  options.single-user.home-manager = {
    enable = lib.mkEnableOption "If the user is managed by home manager" // {
      default = config.single-user.username != null;
    };

    extraModules = lib.mkOption {
      description = "Extra home manager modules to apply for the user";
      type = types.listOf types.deferredModule;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = { osConfig, ... }: {
      imports = cfg.extraModules;
      home = {
        homeDirectory = osConfig.users.users.${username}.home;
        stateVersion = lib.mkIf isLinux osConfig.system.stateVersion;
      };
    };
  };
}
