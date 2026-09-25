{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gaming.steam;
in
{
  options.gaming.steam.enable = lib.mkEnableOption "Whether to install Steam.";

  config.home.packages = lib.optional cfg.enable (with pkgs; [ steam ]);
}
