{
  pkgs,
  ...
}:
rec {
  imports = [
    ./desktop.nix
    ./disk-config.nix
  ];

  boot.defaults.secureBoot = true;
  # Latest kernel (7.1.3) breaks the interal webcam currently
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-lts-lto-x86_64-v4;

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

  hardware.facter.reportPath = ./facter.json;
  hardware.ipu6.videoDeviceNumber = 99;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };

  user.name = "fxbse";
  single-user.username = user.name;
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
  gaming.steam.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user.name} = {
      applications = {
        "3d-printing".enable = true;
        browser.enable = true;
        email.enable = true;
        multimedia.enable = true;
        office.enable = true;
      };

      gaming.minecraft.enable = true;

      home.packages = with pkgs; [ xournalpp ];
    };
  };

  # DO NOT CHANGE AFTER INSTALLING THE SYSTEM
  system.stateVersion = "25.05"; # Did you read the comment?
}
