{
  lib,
  ...
}:
{

  virtualisation.vmVariant.zramSwap.enable = lib.mkForce false;

  boot.kernel.sysctl."vm.swappiness" = 110;
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };
}
