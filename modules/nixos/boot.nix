{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.boot.defaults;
in
{
  options.boot.defaults = {
    enable = lib.mkEnableOption "default boot configuration" // {
      default = true;
    };

    secureBoot = lib.mkEnableOption "default secure boot configuration";
  };

  config.boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  config.boot.loader.efi = {
    canTouchEfiVariables = lib.mkDefault true;
    efiSysMountPoint = lib.mkDefault "/boot/efi";
  };

  config.environment.systemPackages = with pkgs; lib.optional cfg.secureBoot sbctl;
  config.boot.initrd.systemd.enable = lib.mkIf cfg.secureBoot true;
  config.boot.loader = {
    systemd-boot.enable = !cfg.secureBoot && !config.wsl.enable;
    timeout = lib.mkDefault 0;
  };
  config.boot.lanzaboote = lib.mkIf cfg.secureBoot {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  config.virtualisation.vmVariant.virtualisation = {
    diskSize = 4096;
    memorySize = 4096;
    cores = 4;
  };
}
