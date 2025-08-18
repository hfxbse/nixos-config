{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.development.embedded;
in
{
  options.development.embedded.enable = lib.mkEnableOption "embedded development support";

  config = lib.mkIf cfg.enable {
    services.udev.packages = [ pkgs.platformio-core.udev ];
    users.groups.dialout.members = [ config.user.name ]; # Non-root access to serial ports
  };
}
