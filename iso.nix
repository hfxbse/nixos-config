{
  authorizedKey ? null,
  wifi ? { },
}:
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nodeName = lock.nodes.root.inputs.flake-compat;

  flake =
    let
      flake-compat-archive = "https://github.com/edolstra/flake-compat/archive";
    in
    (import (fetchTarball {
      url =
        lock.nodes.${nodeName}.locked.url
          or "${flake-compat-archive}/${lock.nodes.${nodeName}.locked.rev}.tar.gz";
      sha256 = lock.nodes.${nodeName}.locked.narHash;
    }) { src = ./.; });
in
(
  flake.outputs.nixosConfigurations.iso.config
  // {
    setup = {
      inherit authorizedKey wifi;
    };
  }
).system.build.isoImage
