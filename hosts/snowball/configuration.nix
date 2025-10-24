{ lib, pkgs, ... }:
{
  facter.reportPath = ./facter.json;
  virtualisation.vmVariant.facter.reportPath = lib.mkForce ./facter-vm.json;
  imports = [ ./disk-config.nix ];

  boot = {
    defaults.secureBoot = true;
    loader.timeout = 2;

    kernel.sysctl = {
      "vm.swappiness" = 110;
    };

    # Hardened 6.12 LTS does not boot
    kernelPackages = pkgs.linuxPackages;
  };

  # Should reboot the system if it the system becomes unreponsive
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  virtualisation.vmVariant.zramSwap.enable = lib.mkForce false;
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  networking.hostName = "snowball";
  user.name = "maintainer";

  # Set your time zone.
  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  networking.firewall.enable = true;

  virtualisation.vmVariant = {
    networking.nat.externalInterface = lib.mkForce "eth0";
    server.immich.accelerationDevices = lib.mkForce [ ];

  };
  programs.nixvim.clipboard.providers.wl-copy.enable = false;
  environment.systemPackages = with pkgs; [
    btop
    htop
    mergerfs
    mergerfs-tools
    s-tui
  ];

  fileSystems."/var/lib/immich/media" = {
    depends = [
      "/mnt/immich/memory-card"
      "/mnt/immich/usb-drive"
      "/mnt/immich/boot-drive"
    ];
    device = "/mnt/immich/*";
    fsType = "mergerfs";
    options = [
      "defaults"
      "fsname=mergerfs-immich"
    ];
  };

  server = {
    enable = true;
    externalNetworkInterface = "eno1";

    immich = {
      enable = true;
      dataDir = "/var/lib/immich";
      accelerationDevices = [ "/dev/dri/renderD128" ];
      systemStateVersion = "25.11";
    };
  };

  # NEVER CHANGE AFTER INSTALLING THE SYSTEM
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
