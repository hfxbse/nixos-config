{
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./disk-config.nix ];
  facter.reportPath = ./facter.json;

  # Regression bug for ipu6 with Linux 6.16
  # See https://github.com/intel/ipu6-drivers/issues/372
  # The issue prevents the device to be suspended or rebootet properly.
  # At the same time the latest LTS kernel (6.12) does not support the volumn butons.
  boot.kernelPackages = pkgs.linuxPackages_6_15;
  hardware.ipu6 = {
    enable = true;
    platform = "ipu6";
  };

  user.name = "fxbse";
  desktop = {
    enable = true;
    auto-rotate.enable = true;
    login = "auto"; # No need to login again to reach the desktop after LUKS decryption
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
          screen-rotate.extensionUuid # Does get overridden otherwise
          unblank.extensionUuid
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

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "25.05"; # Did you read the comment?
}
