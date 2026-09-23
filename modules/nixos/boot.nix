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

  config = {
    boot.tmp.cleanOnBoot = true;
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    boot.loader.efi = {
      canTouchEfiVariables = lib.mkDefault true;
      efiSysMountPoint = lib.mkDefault "/boot/efi";
    };

    environment.systemPackages = lib.optional cfg.secureBoot pkgs.sbctl;
    boot.initrd.systemd.enable = lib.mkIf cfg.secureBoot true;
    boot.loader = {
      systemd-boot.enable = !cfg.secureBoot && !config.wsl.enable;
      timeout = lib.mkDefault 0;
    };

    boot.lanzaboote = lib.mkIf cfg.secureBoot {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    virtualisation.vmVariant.virtualisation = {
      diskImage = null;
      diskSize = 4096;
      memorySize = 4096;
      cores = 4;
    };
  };
}
