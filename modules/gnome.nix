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
    vinagre
    simple-scan
  ]);

  services.xserver.excludePackages = [ pkgs.xterm ];
}
