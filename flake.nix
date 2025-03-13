{
  description = "A helper tool to initialize Nix templates from this repository";

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
      quick = pkgs.callPackage (import ./quick.nix) {};
      default = self.packages.${system}.quick;
    });
  };
}
