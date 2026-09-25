{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.applications."3d-printing";
in
{
  options.applications."3d-printing".enable = lib.mkEnableOption "Whether to install 3d printing tools.";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      freecad-wayland
      orca-slicer
    ];
  };
}
