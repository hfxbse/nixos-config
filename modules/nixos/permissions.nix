{ config, lib, ... }:
{
  security.sudo = {
    enable = lib.mkDefault true;
    extraConfig = ''
      Defaults:root,%wheel timestamp_timeout=30
    '';
  };

  users.users.${config.user.name}.extraGroups = lib.optional config.security.sudo.enable "wheel";
}
