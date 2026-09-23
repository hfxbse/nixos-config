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
      devShells = perSystem (
        system: pkgs: {
          sbom = pkgs.mkShell {
            packages = with pkgs; [ sbomnix ];
          };
        }
      );

      packages = perSystem (
        system: pkgs: {
          ci-version-checker = pkgs.callPackage (import ./ci-version-checker.nix) { };
        }
      );
    };
}
