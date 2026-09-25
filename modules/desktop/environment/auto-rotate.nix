{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.desktop.environment.auto-rotate;
in
{
  options.desktop.environment.auto-rotate.enable =
    lib.mkEnableOption "If auto-rotation of the screen using the accelorometer of the device should be enabled.";

  config = lib.mkIf cfg.enable {
    hardware.sensor.iio.enable = true;
    desktop.environment.gnome.extraExtensions = with pkgs.gnomeExtensions; [ screen-rotate ];
  };
}
