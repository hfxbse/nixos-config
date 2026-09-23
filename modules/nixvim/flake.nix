{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      evalConfig =
        system:
        inputs.nixvim.lib.evalNixvim {
          inherit system;
          modules = [
            ./.
            { nixpkgs.source = inputs.nixpkgs; }
          ];
        };

      perSystem =
        generator:
        inputs.nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-darwin"
        ] (system: generator system inputs.nixpkgs.legacyPackages.${system});
    in
    {
      checks = perSystem (
        system: pkgs: {
          nixvim = (evalConfig system).config.build.test;
        }
      );

      nixosModules.nixvim = {
        nixpkgs.overlays = [ inputs.self.overlays.nixvim ];
      };

      packages = perSystem (
        system: pkgs: {
          nixvim = pkgs.callPackage (
            {
              extraModules ? [ ],
              ...
            }:
            ((evalConfig system).extendModules { modules = extraModules; }).config.build.package
          ) { };
        }
      );

      overlays.nixvim = final: prev: {
        inherit (inputs.self.packages.${prev.stdenv.hostPlatform.system}) nixvim;
      };
    };
}
