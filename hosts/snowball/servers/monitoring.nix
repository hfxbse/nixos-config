{ ... }:
{
  server.services.monitoring = {
    agent = {
      enable = true;
      environmentFile = "/var/lib/secrets/beszel/agent.env";
    };

    ui = {
      enable = true;
      domain = "monitoring.fxbse.com";
    };
  };
}
