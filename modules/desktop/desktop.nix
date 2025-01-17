{ config, host, lib, pkgs, ... }:
let
  cfg = config.desktop;
  hostname = host.name;
  username = host.user.name;
in
{
  imports = [ ./gnome.nix ];

  options.desktop = {
    enable = lib.mkEnableOption "desktop environment";

    type = lib.mkOption {
      type = lib.types.enum [ "gnome" ];
      description = "Which destop environmnet setup should be applied";
      default = "gnome";
    };

    touchpad.enable = lib.mkOption {
      type = lib.types.bool;
      description = "Whether to enable touchpad support";
      default = true;
    };

    login = lib.mkOption {
      type = lib.types.enum [ "manuel" "auto" ];
      description = "Whether the login should be done manuel by the user or automatic";
      default = "manuel";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.hostName = lib.mkDefault hostname;
    networking.networkmanager.enable = lib.mkDefault true;

    # not to sure why this is done, but this is what the installer set up
    # settings from avahi-daemon.nix where mdns is replaced with mdns4
    services.avahi.nssmdns4 = false; # Use the settings from below
    system.nssModules = pkgs.lib.optional (!config.services.avahi.nssmdns4) pkgs.nssmdns;
    system.nssDatabases.hosts = with pkgs.lib; optionals (!config.services.avahi.nssmdns4) (mkMerge [
      (mkBefore [ "mdns4_minimal [NOTFOUND=return]" ]) # before resolve
      (mkAfter [ "mdns4" ]) # after dns
    ]);

    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    services.libinput.enable = lib.mkDefault cfg.touchpad.enable;

    # Enable automatic login for the user.
    services.displayManager.autoLogin.enable = cfg.login == "auto";
    services.displayManager.autoLogin.user = lib.mkDefault username;

    boot.supportedFilesystems = [ "ntfs"  ];
    services.gvfs.enable = lib.mkDefault true;

    nixpkgs.config.allowUnfree = true;
  };
}
