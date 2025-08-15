{
  config,
  lib,
  pkgs,
  ...
}:
let
  allowUnfree = config.nixpkgs.config.allowUnfree;
in
{
  services.printing = {
    logLevel = "debug";
    drivers = lib.optional allowUnfree pkgs.cups-brother-hl3172cdw;
  };
}
