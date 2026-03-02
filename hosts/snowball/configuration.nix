{
  lib,
  pkgs,
  ...
}:
{
  facter.reportPath = ./facter.json;
  virtualisation.vmVariant.facter.reportPath = lib.mkForce ./facter-vm.json;
  imports = [
    ./disk-config.nix
    ./remote-access.nix
    ./servers
    ./wifi-bridge.nix
    ./zram.nix
  ];

  boot = {
    # Hardened 6.12 LTS does not boot
    kernelPackages = pkgs.linuxPackages;
    defaults.secureBoot = true;
    loader.timeout = 2;
  };

  # Should reboot the system if it the system becomes unreponsive
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  networking.hostName = "snowball";
  user.name = "maintainer";
  virtualisation.vmVariant = {
    networking.hostName = lib.mkForce "vm-snowball";
    boot.initrd.services.udev.rules = ''
      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", KERNEL=="eth*", NAME="eno1"
    '';
  };

  time.timeZone = "UTC";

  backups = {
    enable = true;
    interval = 4;
    repository.urlFile = "/var/lib/backup-repository/url";
    repository.passwordFile = "/var/lib/backup-repository/password";
    snapshotPath = "/mnt/snapshots";
    volumePaths = [
      "/root"
      "/srv"
      "/home"
      "/var"
    ];
  };

  programs.nixvim.clipboard.providers.wl-copy.enable = false;
  environment.systemPackages = with pkgs; [
    btop
    dnsutils
    htop
    s-tui
  ];

  system.autoUpgrade = {
    operation = lib.mkForce "switch";
    allowReboot = true;
    rebootWindow = {
      lower = "03:00";
      upper = "04:00";
    };
  };

  # NEVER CHANGE AFTER INSTALLING THE SYSTEM
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
