{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.applications.office;
in
{
  options.applications.office = {
    enable = lib.mkEnableOption "Whether to install basic office utilits.";
    suite.enable = lib.mkEnableOption "Whether to install a full office suite.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional cfg.suite.enable pkgs.libreoffice ++ (with pkgs; [ pdfarranger ]);
  };
}
