{ config, lib, ... }:
let
  inherit (lib) types;
  cfg = config.desktop.environment;
in
{
  imports = [
    ./audio.nix
    ./auto-rotate.nix
    ./gnome.nix
    ./networking.nix
    ./peripherals.nix
    ./thumbnails.nix
  ];

  options.desktop.environment = {
    enable = lib.mkEnableOption "desktop environment";

    type = lib.mkOption {
      type = types.enum [ "gnome" ];
      description = "Which desktop environment setup should be applied";
      default = "gnome";
    };
  };

  config = lib.mkIf cfg.enable {
    # Support mounting NTFS drives
    boot.supportedFilesystems = [ "ntfs" ];
    system.autoUpgrade.allowReboot = false;
    backups.optOutFilenames = [ ".no-backup" ];
  };
}
