{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gaming.minecraft;
in
{
  options.gaming.minecraft.enable = lib.mkEnableOption "Whether to install a Minecraft lauchner.";

  config.home.packages = lib.optional cfg.enable (with pkgs; prismlauncher);
}
