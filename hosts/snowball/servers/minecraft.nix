{ lib, ... }:
{
  server.services.minecraft = {
    enable = true;
    domain = "minecraft.fxbse.com";
    memory.max = 4096;
  };

  virtualisation.vmVariant = {
    # Too resource heavy and not important enough to deal with it every time
    server.services.minecraft.enable = lib.mkForce false;
  };
}
