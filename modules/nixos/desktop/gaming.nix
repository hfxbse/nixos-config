{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.gaming;
in
{
  options.desktop.gaming = {
    enable = lib.mkEnableOption "gaming";
    steam.enable = lib.mkEnableOption "Steam support" // {
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

    users.users.${config.user.name}.packages = with pkgs; [ prismlauncher ];
  };
}
