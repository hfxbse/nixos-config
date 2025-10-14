{
  config,
  lib,
  pkgs,
  ...
}:
{
  facter.reportPath = ./facter.json;
  imports = [
    ./desktop.nix
    ./disk-config.nix
  ];

  boot.defaults.secureBoot = true;

  # Regression bug for ipu6 starting with Linux 6.16
  # See https://github.com/intel/ipu6-drivers/issues/381
  # The issue prevents the device to be suspended or rebootet properly.
  hardware.ipu6.enable = lib.mkForce false;

  user.name = "fxbse";
  networking.hostName = "ice-skate";

  backups = {
    enable = true;
    repositoryUrlFile = "/var/lib/backup-repository/url";
    repositoryPasswordFile = "/var/lib/backup-repository/password";
    rootPaths = [
      "/home"
      "/var"
    ];
  };

  users.users.${config.user.name}.packages = with pkgs; [ xournalpp ];

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "25.05"; # Did you read the comment?
}
