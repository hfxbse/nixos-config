{ config, lib, ... }:
let
  types = lib.types;
  cfg = config.server;
in
{
  options.server.containerNames = lib.mkOption {
    # Required as getting them dynamically results in an infinite recursion
    description = "Names of the server containers to which apply the default config to.";
    type = types.listOf types.str;
    default = [ ];
  };

  imports = [
    ./dummy.nix
    ./dummy-http.nix
    ./reverse-proxy.nix
    ./router.nix
  ];

  config.containers = lib.genAttrs cfg.containerNames (name: {
    autoStart = true;
    privateUsers = "pick";
    config.system.stateVersion = config.system.stateVersion;
  });
}
