{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (config.desktop) environment;
  allowUnfree =  config.nixpkgs.config.allowUnfree or false;
  cfg = config.desktop.environment.peripherals;
in
{
  options.desktop.environment.peripherals = {
    mtp.enable = lib.mkEnableOption "Whether to allow mounting MTP devices" // {
      default = environment.enable;
    };

    printers.enable = lib.mkEnableOption "Whether to configure printers and scanners" // {
      default = environment.enable;
    };

    touchpad.enable = lib.mkEnableOption "Whether to enable touchpad support" // {
      default = environment.enable;
    };

    wooting.users = lib.mkOption {
      description = "Which users got a Wooting keyboard";
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = rec {
    services.libinput.enable = lib.mkDefault cfg.touchpad.enable;

    hardware.wooting.enable = (builtins.length cfg.wooting.users) > 0;
    users.groups.input.members = lib.optional hardware.wooting.enable cfg.wooting.users;

    services.gvfs.enable = cfg.mtp.enable;

    hardware.sane.enable = cfg.printers.enable;
    services.printing = {
      enable = cfg.printers.enable;
      logLevel = "debug";
      drivers = lib.optional allowUnfree pkgs.cups-brother-hl3172cdw;
    };

    # Disables mDNS for IPv6 addresses fixing an issue with printers not being discoverd
    # settings from avahi-daemon.nix where mdns is replaced with mdns4
    services.avahi.nssmdns4 = cfg.printers.enable; # Use the settings from below
    system.nssModules = pkgs.lib.optional (!config.services.avahi.nssmdns4) pkgs.nssmdns;
    system.nssDatabases.hosts =
      with pkgs.lib;
      optionals (!config.services.avahi.nssmdns4) (mkMerge [
        (mkBefore [ "mdns4_minimal [NOTFOUND=return]" ]) # before resolve
        (mkAfter [ "mdns4" ]) # after dns
      ]);
  };
}
