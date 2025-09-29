{ config, lib, ... }:
let
  cfg = config.user;
in
{
  options.user.name = lib.mkOption {
    description = "The main user's username for the maschine";
    type = lib.types.str;
    default = "nixos";
  };

  config.users.users.${cfg.name}.isNormalUser = true;
  config.virtualisation = rec {
    vmVariantWithBootLoader = vmVariant;
    vmVariant = {
      security.sudo.wheelNeedsPassword = false;
      services.getty.autologinUser = config.user.name;
    };
  };
}
