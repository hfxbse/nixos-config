{
  config,
  lib,
  pkgs,
  ...
}:
let
  allowUnfree = config.nixpkgs.config.allowUnfree;
  cfg = config.services.printing;
in
{
  config = lib.mkIf cfg.enable {
    services.printing = {
      logLevel = "debug";
      drivers = lib.optional allowUnfree pkgs.cups-brother-hl3172cdw;
    };

    # Disables mDNS for IPv6 addresses fixing an issue with printers not being discoverd
    # settings from avahi-daemon.nix where mdns is replaced with mdns4
    services.avahi.nssmdns4 = false; # Use the settings from below
    system.nssModules = pkgs.lib.optional (!config.services.avahi.nssmdns4) pkgs.nssmdns;
    system.nssDatabases.hosts =
      with pkgs.lib;
      optionals (!config.services.avahi.nssmdns4) (mkMerge [
        (mkBefore [ "mdns4_minimal [NOTFOUND=return]" ]) # before resolve
        (mkAfter [ "mdns4" ]) # after dns
      ]);
  };
}
