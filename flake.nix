{
  nixConfig = {
    # CachyOS Kernel binary cache
    # See https://github.com/xddxdd/nix-cachyos-kernel?tab=readme-ov-file#binary-cache
    extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
    extra-trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "./modules/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    ai.url = "./modules/ai";
    ai.inputs.nixpkgs.follows = "nixpkgs";

    backups.url = "./modules/backups";
    backups.inputs.nixpkgs.follows = "nixpkgs";

    servers.url = "./modules/servers";
    servers.inputs.nixpkgs.follows = "nixpkgs";

    nixos.url = "./modules/nixos";
    nixos.inputs.nixpkgs.follows = "nixpkgs";

    ci.url = "./modules/ci";
    ci.inputs.nixpkgs.follows = "nixpkgs";

    nix.url = "./modules/nix";
    nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      mergeInputs = builtins.foldl' nixpkgs.lib.recursiveUpdate;
    in
    {
      checks = with inputs; mergeInputs nixvim.checks [ ];

      darwinModules = with inputs; mergeInputs nix.darwinModules [
          nixvim.darwinModules
      ];

      nixosModules =
        with inputs;
        mergeInputs backups.nixosModules [
          nix.nixosModules
          nixos.nixosModules
          nixvim.nixosModules
          servers.nixosModules
        ];

      packages =
        with inputs;
        mergeInputs ai.packages [
          backups.packages
          ci.packages
          nixvim.packages

          {
            # Standalone one-off packages
            x86_64-linux =
              nixpkgs.lib.genAttrs
                [
                  "flaketex"
                  "jeniffer2"
                  "quick-template"
                  "scan-crop"
                ]
                (
                  name:
                  with nixpkgs.legacyPackages.x86_64-linux;
                  with javaPackages;
                  with python3Packages;
                  callPackage (import ./derivations/${name}.nix) { latex = texliveFull; }
                );
          }
        ];

      overlays =
        with inputs;
        mergeInputs ai.overlays [
          backups.overlays
          nixos.overlays
          nixvim.overlays
          servers.overlays
        ];

      devShells = with inputs; mergeInputs ci.devShells [ ];

      templates = {
        default = self.templates.baseline;
        baseline = {
          description = "A baseline flake";
          path = ./templates/baseline;
        };
      };

      nixosConfigurations = nixpkgs.lib.genAttrs [ "ice-skate" "snowball" "geras" ] (
        name:
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = (builtins.attrValues self.nixosModules) ++ [
            ./hosts/${name}/configuration.nix
            {
              user.fullName = nixpkgs.lib.mkDefault "Fabian Haas";
              nixpkgs.overlays = [
                (final: prev: {
                  quick-template = self.packages.${system}.quick-template;
                })
              ];
            }
          ];
        }
      );

      darwinConfigurations = nixpkgs.lib.genAttrs [ "MN-EXM79RNYVFQ1" ] (
        name:
        inputs.nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = (builtins.attrValues self.darwinModules) ++ [
            ./hosts/${name}/configuration.nix
          ];
        }
      );
    };
}
