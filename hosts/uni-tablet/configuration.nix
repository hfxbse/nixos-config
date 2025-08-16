{ pkgs, lib, ... }:
{
  imports = [ ./disk-config.nix ];
  facter.reportPath = ./facter.json;

  hardware.sensor.iio.enable = true;
  environment.systemPackages = with pkgs; [
    gnomeExtensions.screen-rotate
  ];
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org/gnome/shell]
    enabled-extensions=['screen-rotate@shyzus.github.io']
  '';

  user.name = "fxbse";
  desktop = {
    enable = true;
    login = "auto"; # No need to login againt to reach the desktop after LUKS decryption
  };

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "25.05"; # Did you read the comment?
}
