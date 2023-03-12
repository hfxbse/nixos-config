{ pkgs, ... }:
{
  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
    gnome-2048
  ]) ++ ( with pkgs.gnome; [
    cheese
    gnome-music
    gnome-maps
    gnome-contacts
    epiphany
    geary
    totem
    tali
    iagno
    hitori
    atomix
    yelp
    polari
    anjuta
    vinagre
    simple-scan
  ]);

  services.xserver.excludePackages = [ pkgs.xterm ];
}
