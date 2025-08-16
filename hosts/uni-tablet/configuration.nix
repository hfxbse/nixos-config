{ pkgs, ... }:
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
    auto-rotate = true;
    login = "auto"; # No need to login again to reach the desktop after LUKS decryption
  };

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "25.05"; # Did you read the comment?
}
