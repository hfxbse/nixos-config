{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.development.android;
in
{
  options.development.android.enable = lib.mkEnableOption "Android development support";

  config = lib.mkIf cfg.enable {
    programs.adb.enable = true;
    services = {
      gvfs.enable = lib.mkDefault true;
      udev.packages = [ pkgs.android-udev-rules ];
    };

    users.groups.adbuser.members = [ config.user.name ];
  };
}
