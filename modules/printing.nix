{ config, cups-brother-hl3172cdw, lib, pkgs, ... }:
let
  allowUnfree = config.nixpkgs.config.allowUnfree;
in
{
    services.printing = {
        logLevel = "debug";
        drivers = lib.optional allowUnfree cups-brother-hl3172cdw;
    };
}
