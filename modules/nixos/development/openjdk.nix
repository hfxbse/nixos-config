{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.development.openjdk;
in
{
  options.development.openjdk.enable = lib.mkEnableOption "OpenJDK development support";

  config.programs.nix-ld = lib.mkIf cfg.enable {
    enable = true;
    libraries = (
      with pkgs;
      [
        gtk3
        gdk-pixbuf
        xorg.libXtst
        xorg.libXxf86vm
        xorg.libX11
        glib
        cairo
        pango
        libGL
      ]
    );
  };
}
