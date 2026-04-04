{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop;
  user = config.user;
in
{
  imports = [
    ./3d-printing.nix
    ./auto-rotate.nix
    ./browser.nix
    ./email.nix
    ./fonts.nix
    ./gaming.nix
    ./gnome.nix
    ./multimedia.nix
    ./networking.nix
  ];

  options.desktop = {
    enable = lib.mkEnableOption "desktop environment";

    type = lib.mkOption {
      type = lib.types.enum [ "gnome" ];
      description = "Which desktop environmnet setup should be applied";
      default = "gnome";
    };

    touchpad.enable = lib.mkEnableOption "touchpad support" // {
      default = true;
    };

    login = lib.mkOption {
      type = lib.types.enum [
        "manuel"
        "auto"
      ];
      description = "Whether the login should be done manuel by the user or automatic";
      default = "manuel";
    };
  };

  config = lib.mkIf cfg.enable {
    desktop.networking.enable = lib.mkDefault true;
    services.libinput.enable = lib.mkDefault cfg.touchpad.enable;
    users.groups.input.members = lib.optional config.hardware.wooting.enable user.name;

    services.printing.enable = true;
    hardware.sane = {
      enable = true;
      backends-package = pkgs.sane-backends.overrideAttrs {
        # Enable potentially dangerous Canon 4400F support
        fixupPhase = ''
          sed -i 's/#usb 0x04a9 0x2228/usb 0x04a9 0x2228/' $out/etc/sane.d/genesys.conf
        '';
      };
    };

    # Enable automatic login for the user.
    services.displayManager.autoLogin.enable = cfg.login == "auto";
    services.displayManager.autoLogin.user = lib.mkDefault user.name;

    # Support mounting NTFS drives
    boot.supportedFilesystems = [ "ntfs" ];
    # Support mounting MTP devices
    services.gvfs.enable = lib.mkDefault true;

    system.autoUpgrade.allowReboot = false;
    nixpkgs.config.allowUnfree = true;
  };
}
