{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.office;
in
{
  options.desktop.office = {
    enable = lib.mkEnableOption "office" // {
      default = config.desktop.enable;
    };

    suite.enable = lib.mkEnableOption "office suite";
  };

  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.packages =
      lib.optional cfg.suite.enable pkgs.libreoffice ++ (with pkgs; [ pdfarranger ]);
  };
}
