{
  config,
  lib,
  ...
}:
let
  cfg = config.server.services.dummy-http;
in
{
  options.server.services.dummy-http = {
    enable = lib.mkEnableOption {
      description = "A dummy HTTP server.";
    };

    domain = lib.mkOption {
      description = "The domain to responde to.";
      type = lib.types.str;
      default = "example.com";
    };
  };

  config = lib.mkIf cfg.enable {
    # Can be tested using curl
    # curl http://example.com --resolve 'example.com:80:127.0.0.1'
    # This tells curl to resolve the domain to the reverse-proxy's IP
    server.services.reverse-proxy.virtualHosts.${cfg.domain} = {
      containerName = "dummy-http";
      port = 80;
      public = true;
    };

    containers.dummy-http = {
      config = {
        networking.firewall.allowedTCPPorts = [ 80 ];
        services.httpd.enable = true;
      };
    };
  };
}
