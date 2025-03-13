{
  description = "Flutter tools for embedded Linux (eLinux)";

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
      flutter-elinux = pkgs.callPackage ( import ./flutter-elinux.nix ) {};
      default = self.packages.${system}.flutter-elinux;
    });
  };
}
