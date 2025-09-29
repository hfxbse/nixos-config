{ config, lib, ... }:
{
  virtualisation.vmVariant = {
    security.sudo.wheelNeedsPassword = false;
    services.getty.autologinUser = config.user.name;

    zramSwap.enable = lib.mkForce false;
    virtualisation = {
      memorySize = 4096;
      cores = 4;
    };

    networking.nat.externalInterface = lib.mkForce "eth0";
  };
}
