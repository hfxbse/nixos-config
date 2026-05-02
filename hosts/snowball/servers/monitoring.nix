{ lib, ... }:
{
  server.services.monitoring = {
    agent = {
      enable = true;
      environmentFile = "/var/lib/secrets/beszel/agent.env";
      extraVolumes = {
        "/mnt/immich/memory-card".label = "Memory Card";
        "/mnt/immich/usb-drive".label = "USB Drive";
      };
    };

    ui = {
      enable = true;
      domain = "monitoring.fxbse.com";
    };
  };

  virtualisation.vmVariant.server.services.monitoring.agent.extraVolumes = lib.mkForce { };
}
