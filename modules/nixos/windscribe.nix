{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.windscribe;
in
{
  options.programs.windscribe.enable = lib.mkEnableOption "the Windscribe desktop application";

  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.packages = with pkgs; [ windscribe-desktop-app ];
    users.groups.windscribe = {
      gid = 988;
      members = [ config.user.name ];
    };
  };
}
