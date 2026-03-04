{
  config,
  lib,
  ...
}:
let
  cfg = config.server.services.dummy-http;
in
{
  options.server.services.dummy-http.enable = lib.mkEnableOption {
    description = "A dummy HTTP server.";
  };

  config = lib.mkIf cfg.enable {
    # Can be tested using curl
    # curl http://example.com --resolve 'example.com:80:127.0.0.1'
    # This tells curl to resolve the domain to the reverse-proxy's IP
    server.services.reverse-proxy.virtualHosts."example.com" = {
      containerName = "dummy-http";
      port = 80;
    };

    containers.dummy-http = {
      config = {
        networking.firewall.allowedTCPPorts = [ 80 ];
        services.httpd.enable = true;
      };
    };
  };
}
