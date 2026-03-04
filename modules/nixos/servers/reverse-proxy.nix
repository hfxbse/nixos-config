{
  config,
  lib,
  ...
}:
let
  cfg = config.server.services.reverse-proxy;
in
{
  options.server.services.reverse-proxy.enable = lib.mkEnableOption {
    description = "A level 7 HTTP reverse-proxy.";
  };

  config = lib.mkIf cfg.enable {
    server.containerNames = [ "reverse-proxy" ];
    containers.reverse-proxy = {
      config = {
        services.haproxy.enable = true;
      };
    };
  };
}
