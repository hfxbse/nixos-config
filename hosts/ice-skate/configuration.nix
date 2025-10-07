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

  boot.defaults.secureBoot = true;

  # Regression bug for ipu6 from nixpkgs starting with Linux 6.16
  # See https://github.com/intel/ipu6-rivers/issues/372
  # The issue prevents the device to be suspended or rebootet properly.
  nixpkgs.overlays = [
    (final: prev: {
      linuxPackages_latest = prev.linuxPackages_latest.extend (
        lpFinal: lpPrev: {
          ipu6-drivers = lpPrev.ipu6-drivers.overrideAttrs (old: {
            version = "unstable-2025-10-07";
            src = prev.fetchFromGitHub {
              owner = "intel";
              repo = "ipu6-drivers";
              rev = "69b2fde9edcbc24128b91541fdf2791fbd4bf7a4";
              hash = "sha256-pe7lqK+CHpgNWpC8GEZ3FKfYcuVuRUaWlW17D8AsrSk=";
            };
          });
        }
      );
    })
  ];

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

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "25.05"; # Did you read the comment?
}
