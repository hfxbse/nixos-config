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
    environment.systemPackages = with pkgs.gnomeExtensions; [ screen-rotate ];

    programs.dconf.profiles.user.databases = [
      {
        settings = with pkgs.gnomeExtensions; {
          "org/gnome/shell".enabled-extensions = [ screen-rotate.extensionUuid ];
        };
      }
    ];
  };
}
