{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop;
  extensions = with pkgs.gnomeExtensions; [
    caffeine
    power-off-options
    quick-settings-audio-panel
  ];
in
{
  options.desktop.gnome.extraExtensions = lib.mkOption {
    description = "Extra extensions to be install in the GNOME extensions.";
    type = lib.types.listOf lib.types.package;
    default = [ ];
  };

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
          "org/gnome/shell".enabled-extensions = map ({ extensionUuid, ... }: extensionUuid) (
            cfg.gnome.extraExtensions ++ extensions
          );

          "org/gnome/shell/extensions/quick-settings-audio-panel" = {
            panel-type = "merged-panel";
            merged-panel-position = "top";
            pactl-path = lib.getExe' pkgs.pulseaudio "pactl";

            create-mpris-controllers = false;
            mpris-controllers-are-moved = false;

            create-applications-volume-sliders = true;
            group-applications-volume-sliders = true;
          };
        };
      }
    ];

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "blackbox";
    };

    environment.systemPackages =
      with pkgs;
      [
        blackbox-terminal
        gnome-network-displays
        papers
      ]
      ++ extensions
      ++ cfg.gnome.extraExtensions;

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
