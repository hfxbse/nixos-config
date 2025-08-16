{ pkgs, ... }:
{
  imports = [ ./disk-config.nix ];
  facter.reportPath = ./facter.json;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

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
