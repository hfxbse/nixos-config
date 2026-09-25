{ config, lib, ... }:
let
  cfg = config.desktop.environment.audio;
in
{
  options.desktop.environment.audio.enable = lib.mkEnableOption "If the desktop environment audio should be configured." // {
    default = config.desktop.environment.enable;
  };

  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
