{ config, lib, pkgs, ... }:
let
  cfg = config.gaming;
  user = config.user;
in
{
  options.gaming = {
    enable = lib.mkEnableOption "the gaming setup";

    steam.enable = lib.mkOption {
      description = "Whether to setup Steam";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.steam = lib.mkIf cfg.steam.enable {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    hardware.steam-hardware.enable = cfg.steam.enable;
  };
}
