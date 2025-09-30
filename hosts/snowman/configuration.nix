{ lib, pkgs, ... }:
{
  facter.reportPath = ./facter.json;
  imports = [ ./disk-config.nix ];

  boot = {
    defaults.secureBoot = true;
    loader.timeout = 3;

    # System frequently freezes completely on newer kernel version
    # Seems to happen when data is read or written to the storage
    # Might be related to https://bugzilla.kernel.org/show_bug.cgi?id=218821
    kernelPackages = pkgs.linuxPackages_6_1_hardened;
    blacklistedKernelModules = [
      "hid_asus"
      "asus_nb_wmi"
      "asus_wmi"
      "battery"
      "asus_wireless"
    ];
  };

  networking.hostName = "snowman";
  user.name = "maintainer";

  virtualisation.vmVariant.zramSwap.enable = lib.mkForce false;
  zramSwap = {
    enable = true;
    memoryPercent = 250;
    writebackDevice = "/dev/mapper/zram-backing-crypted";
  };

  nix.settings = {
    max-jobs = 1;
    cores = 1;
  };

  # Set your time zone.
  time.timeZone = "UTC";

  programs.nixvim.clipboard.providers.wl-copy.enable = false;
  environment.systemPackages = with pkgs; [
    htop
    s-tui
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  networking.firewall.enable = true;

  virtualisation.vmVariant.networking.nat.externalInterface = lib.mkForce "eth0";
  server = {
    enable = true;
    externalNetworkInterface = "enp1s0";

    immich = {
      enable = true;
      systemStateVersion = "25.05";
    };
  };

  # NEVER CHANGE AFTER INSTALLING THE SYSTEM
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
