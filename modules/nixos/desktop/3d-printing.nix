{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop."3d-printing";
in
{
  options.desktop."3d-printing".enable = lib.mkEnableOption "3d printing tools";

  config = lib.mkIf (config.desktop.enable && cfg.enable) {
    users.users.${config.user.name}.packages = with pkgs; [
      freecad-wayland
      orca-slicer
    ];
  };
}
