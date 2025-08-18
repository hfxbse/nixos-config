{ config, lib, pkgs, ... }:
let
  cfg = config.boot.defaults;
in
{
  options.boot.defaults.enable = lib.mkEnableOption "default boot configuration" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  boot.loader.efi.efiSysMountPoint = lib.mkDefault "/boot/efi";
  };
}
