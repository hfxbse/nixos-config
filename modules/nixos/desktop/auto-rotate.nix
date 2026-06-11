{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.desktop.auto-rotate;
in
{
  options.desktop.auto-rotate.enable = lib.mkEnableOption "auto-rotation of the screen using the accelorometer of the device.";

  config = lib.mkIf cfg.enable {
    hardware.sensor.iio.enable = true;
    desktop.gnome.extraExtensions = with pkgs.gnomeExtensions; [ screen-rotate ];
  };
}
