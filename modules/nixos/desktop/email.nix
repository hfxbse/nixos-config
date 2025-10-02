{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.email;
in
{

  options.desktop.email.enable = lib.mkEnableOption "emailing tools" // {
    default = config.desktop.enable;
  };

  config = lib.mkIf cfg.enable {
    programs.thunderbird.enable = true;
    users.users.${config.user.name}.packages = with pkgs; [ sieve-editor-gui ];
  };
}
