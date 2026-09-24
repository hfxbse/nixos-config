{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs.lib) recursiveUpdate;
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

      genModule = nixvimModule: {
        imports = [ nixvimModule ];
        programs.nixvim = {
          enable = true;
          nixpkgs.source = inputs.nixpkgs;
          imports = [ ./. ];
        };
      };

      mkDefaultEditor = module: recursiveUpdate module { programs.nixvim.defaultEditor = true; };
      applyOverlay =
        module: recursiveUpdate module { nixpkgs.overlays = [ inputs.self.overlays.nixvim ]; };
    in
    {
      checks = perSystem (
        system: pkgs: {
          nixvim = (evalConfig system).config.build.test;
        }
      );

      darwinModules.nixvim = applyOverlay (genModule inputs.nixvim.nixDarwinModules.nixvim);
      homeModules.nixvim = mkDefaultEditor (genModule inputs.nixvim.homeModules.nixvim);
      nixosModules.nixvim = applyOverlay (mkDefaultEditor (genModule inputs.nixvim.nixosModules.nixvim));

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
