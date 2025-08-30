{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.windscribe;
  windscribe = pkgs.windscribe-desktop-app;
in
{
  options.programs.windscribe.enable = lib.mkEnableOption "the Windscribe desktop application";

  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.packages = [ windscribe ];
    users.groups.windscribe = {
      gid = 988;
      members = [ config.user.name ];
    };

    systemd.user.services.windscribe = {
      enable = true;
      description = "Windscribe service";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${windscribe}/bin/Windscribe";
      };
    };
  };
}
