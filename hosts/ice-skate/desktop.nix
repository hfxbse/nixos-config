{
  lib,
  pkgs,
  ...
}:
{

  desktop = {
    enable = true;
    auto-rotate.enable = true;
  };

  environment.systemPackages = with pkgs.gnomeExtensions; [
    caffeine
    unblank
  ];

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/desktop/screensaver".lock-delay = lib.gvariant.mkUint32 0;

        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-battery-timeout = lib.gvariant.mkInt32 180;
          sleep-inactive-ac-timeout = lib.gvariant.mkInt32 420;
        };

        "org/gnome/shell".enabled-extensions = with pkgs.gnomeExtensions; [
          caffeine.extensionUuid
          unblank.extensionUuid

          # Does get overridden otherwise
          screen-rotate.extensionUuid
          hibernate-status-button.extensionUuid
        ];

        "org/gnome/shell/extensions/unblank".power = false;
      };
    }
    {
      settings = {
        "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 60;
      };
    }
  ];
}
