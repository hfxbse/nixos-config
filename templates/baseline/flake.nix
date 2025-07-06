{
  description = "A baseline flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    defaultSystems = [ "x86_64-linux" ];

    forAllSystems = systems: function: nixpkgs.lib.genAttrs systems (system: function system);
    forAllDefaultSystems = forAllSystems defaultSystems;
  in
  {
    packages = forAllDefaultSystems (system:
    let
        pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      hello = pkgs.hello;
      default = self.packages.${system}.hello;
    });
  };
}
