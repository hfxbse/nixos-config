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
    server.services.reverse-proxy.containerNames = [ "dummy-http" ];
    containers.dummy-http = {
      config = {
        services.httpd.enable = true;
      };
    };
  };
}
