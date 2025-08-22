{
  pkgs,
  ...
}:
{
  facter.reportPath = ./facter.json;
  imports = [
    ./desktop.nix
    ./disk-config.nix
  ];

  # Regression bug for ipu6 with Linux 6.16
  # See https://github.com/intel/ipu6-drivers/issues/372
  # The issue prevents the device to be suspended or rebootet properly.
  # At the same time the latest LTS kernel (6.12) does not support the volumn butons.
  boot.kernelPackages = pkgs.linuxPackages_6_15;
  hardware.ipu6 = {
    enable = true;
    platform = "ipu6";
  };

  boot.defaults.secureBoot = true;

  user.name = "fxbse";

  backups = {
    enable = true;
    repositoryUrl = "rest:https://n65v15sx:D2ai530dU6IBKldB@n65v15sx.repo.borgbase.com";
    repositoryPasswordFile = "/var/lib/repository-password";
    rootPaths = [
      "/home"
      "/var"
    ];
  };

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "25.05"; # Did you read the comment?
}
