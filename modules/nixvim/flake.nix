{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    kotlin-lsp.url = "git+https://git.poz.pet/poz/kotlin-lsp-nix";
    kotlin-lsp.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs.lib) recursiveUpdate;
      getPkgs = with inputs; system: nixpkgs.legacyPackages.${system}.extend self.overlays.kotlin-lsp;

      nixpkgsConfig = {
        nixpkgs = {
          overlays = [ inputs.self.overlays.kotlin-lsp ];
          source = inputs.nixpkgs;
        };
      };

      evalConfig =
        system:
        inputs.nixvim.lib.evalNixvim {
          inherit system;
          modules = [
            ./.
            nixpkgsConfig
          ];
        };

      perSystem =
        generator:
        with inputs;
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-darwin"
        ] (system: generator system (getPkgs system));

      genModule = nixvimModule: {
        imports = [ nixvimModule ];
        programs.nixvim = nixpkgsConfig // {
          enable = true;
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

      overlays =
        let
          genOverlay =
            generator: final: prev:
            generator prev.stdenv.hostPlatform.system;
        in
        {
          nixvim = genOverlay (system: {
            inherit (inputs.self.packages.${system}) nixvim;
          });

          kotlin-lsp = genOverlay (system: {
            kotlin-lsp =
              let
                pkgs = import inputs.nixpkgs {
                  inherit system;
                  config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "kotlin-lsp" ];
                };
              in
              (pkgs.callPackage "${inputs.kotlin-lsp}/package.nix" { }).overrideAttrs (prev: {
                src = pkgs.fetchurl {
                  url =
                    builtins.replaceStrings [ "download-cdn.jetbrains.com" ] [ "download.jetbrains.com" ]
                      prev.src.url;
                  hash = prev.src.outputHash;
                };
              });
          });
        };
    };
}
