{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop;
in
{
  config = lib.mkIf (cfg.enable && cfg.type == "gnome") {
    security.pam.services.gdm.enableGnomeKeyring = true;
    services = {
      displayManager.gdm.enable = lib.mkDefault true;
      desktopManager.gnome.enable = true;
    };

    programs.dconf.profiles.user.databases = [
      {
        settings = {
          "org/gnome/mutter".experimental-features = [ "scale-monitor-framebuffer" ];
          "org/gnome/shell".enabled-extensions = with pkgs.gnomeExtensions; [
            hibernate-status-button.extensionUuid
          ];
        };
      }
    ];

    # HEIC thumbnails in GNOME files
    # See https://github.com/NixOS/nixpkgs/issues/164021
    environment.systemPackages = with pkgs; [
      gnomeExtensions.hibernate-status-button
    ];

    # Allow mounting MTP devices in Nautilus
    services.gvfs.enable = true;

    environment.gnome.excludePackages = (
      with pkgs;
      [
        gnome-tour
        gnome-2048
        cheese
        epiphany
        geary
        totem
        yelp
        simple-scan
        gnome-music
        gnome-maps
        gnome-contacts
        tali
        iagno
        hitori
        atomix
        polari
      ]
    );

    services.xserver.excludePackages = [ pkgs.xterm ];
  };
}
