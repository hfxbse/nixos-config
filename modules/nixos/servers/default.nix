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
    ./dns.nix
    ./dummy.nix
    ./dummy-http.nix
    ./ingress.nix
    ./oidc.nix
    ./reverse-proxy.nix
  ];

  config.containers = lib.genAttrs cfg.containerNames (name: {
    autoStart = lib.mkDefault true;
    privateUsers = lib.mkDefault "pick";
    config.system.stateVersion = lib.mkDefault config.system.stateVersion;
  });
}
