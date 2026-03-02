{
  config,
  lib,
  ...
}:
let
  cfg = config.server.services.dummy;
in
{
  options.server.services.dummy.enable = lib.mkEnableOption {
    description = "A dummy server without any services.";
  };

  config = lib.mkIf cfg.enable {
    server.containerNames = [ "dummy" ];
  };
}
