{ pkgs, ... }: {
  programs.nix-ld.libraries = with pkgs; [
    gtk3
    gdk-pixbuf
    xorg.libXtst
    xorg.libXxf86vm
    xorg.libX11
    glib
    cairo
    pango
    libGL
  ];
}
