{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    inputs:
    let
      perSystem =
        generator:
        inputs.nixpkgs.lib.genAttrs [
          "x86_64-linux"
        ] (system: generator system inputs.nixpkgs.legacyPackages.${system});
    in
    {
      nixosModules.restic-backups = {
        imports = [
          ./restic
        ];

        nixpkgs.overlays = builtins.attrValues inputs.self.overlays;
      };

      packages = perSystem (
        system: pkgs: {
          by-disk-snapshotter = pkgs.callPackage (import ./by-disk-snapshotter.nix) { };
        }
      );

      overlays.by-disk-snapshotter =
        final: prev:
        let
          packages = inputs.self.packages.${prev.stdenv.hostPlatform.system};
        in
        {
          inherit (packages) by-disk-snapshotter;
        };
    };
}
