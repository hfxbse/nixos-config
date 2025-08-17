{
  config,
  pkgs,
  lib,
  ...
}:
let
  enable = config.desktop.auto-rotate;
in
{
  options.desktop.auto-rotate = lib.mkEnableOption "auto-rotation of the screen using the accelorometer of the device.";

  config = lib.mkIf enable {
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
