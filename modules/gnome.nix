{ lib, pkgs, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = lib.mkDefault true;
    desktopManager.gnome.enable = true;
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
    gnome-2048
    cheese
    epiphany
    geary
    totem
    yelp
    simple-scan
  ]) ++ ( with pkgs.gnome; [
    gnome-music
    gnome-maps
    gnome-contacts
    tali
    iagno
    hitori
    atomix
    polari
    vinagre
  ]);

  services.xserver.excludePackages = [ pkgs.xterm ];
}
