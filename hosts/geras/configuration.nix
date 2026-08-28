{
  pkgs,
  ...
}:
{
  imports = [
    ./disk-config.nix
  ];

  boot.defaults.secureBoot = true;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;
  boot.kernelParams = [
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percent=25"
    "zswap.shrinker_enabled=1"
  ];

  hardware.facter.reportPath = ./facter.json;

  user.name = "euse";
  networking.hostName = "geras";

  backups = {
    enable = true;
    repository = {
      urlFile = "/var/lib/secrets/borgbase/url";
      passwordFile = "/var/lib/secrets/borgbase/password";
    };

    volumePaths = [
      "/home"
      "/var"
    ];
  };

  localization.language = "de";
  desktop = {
    enable = true;
    email.sieve = false;
  };

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "26.05"; # Did you read the comment?
}
