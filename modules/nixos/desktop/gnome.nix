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
    # https://github.com/NixOS/nixpkgs/issues/149812#issuecomment-3647060694
    environment.extraInit = ''
      export XDG_DATA_DIRS="$XDG_DATA_DIRS:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    '';

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

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "blackbox";
    };

    environment.systemPackages = with pkgs; [
      blackbox-terminal
      gnome-network-displays
      gnomeExtensions.hibernate-status-button
      papers
    ];

    # For network displays
    networking.firewall.allowedTCPPorts = [
      7236 # Miracast
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
        evince
        geary
        totem
        yelp
        simple-scan
        gnome-music
        gnome-maps
        gnome-contacts
        gnome-console
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
