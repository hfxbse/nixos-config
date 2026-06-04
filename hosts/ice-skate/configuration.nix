{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./desktop.nix
    ./disk-config.nix
  ];

  boot.defaults.secureBoot = true;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v4;

  boot.kernelParams = [
    "zswap.enabled=1"
    "zswap.compressor=zstd"
    "zswap.max_pool_percent=25"
    "zswap.shrinker_enabled=1"

    "amdgpu.gpu_recovery=1"
    "amdgpu.lockup_timeout=3600000"
    "iommu=pt"
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

  # Regression bug for ipu6 starting with Linux 6.16
  # See https://github.com/intel/ipu6-drivers/issues/381
  # The issue prevents the device to be suspended or rebootet properly.
  hardware.facter.reportPath = ./facter.json;
  hardware.ipu6.enable = lib.mkForce false;

  user.name = "fxbse";
  networking.hostName = "ice-skate";

  backups = {
    enable = true;
    repository = {
      urlFile = "/var/lib/backup-repository/url";
      passwordFile = "/var/lib/backup-repository/password";
    };

    volumePaths = [
      "/home"
      "/var"
    ];
  };

  development.network.enable = true;
  desktop."3d-printing".enable = true;
  desktop.gaming.enable = true;
  users.users.${config.user.name}.packages = with pkgs; [ xournalpp ];

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "25.05"; # Did you read the comment?
}
