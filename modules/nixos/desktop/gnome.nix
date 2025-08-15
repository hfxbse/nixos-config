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
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = lib.mkDefault true;
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverrides = ''
          [org.gnome.mutter]
          experimental-features=['scale-monitor-framebuffer']
        '';
      };
    };

    # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    # HEIC thumbnails in GNOME files
    # See https://github.com/NixOS/nixpkgs/issues/164021
    environment.systemPackages = [
      pkgs.libheif
      pkgs.libheif.out
    ];
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
