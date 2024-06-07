{ pkgs, config, lib, ... }:
let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';
in
{
  environment.systemPackages = [ nvidia-offload ];

  hardware.opengl = {
    driSupport32Bit = true;
    enable = true;
  };

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.production;
    modesetting.enable = true;
    prime = {
      offload.enable = true;
      intelBusId = lib.mkDefault "PCI:0:2:0";
      nvidiaBusId = lib.mkDefault "PCI:1:0:0";
    };
    nvidiaSettings = false;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
  };

  services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];

}
