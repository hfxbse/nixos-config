{
  nixConfig = {
    # CachyOS Kernel binary cache
    # See https://github.com/xddxdd/nix-cachyos-kernel?tab=readme-ov-file#binary-cache
    extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
    extra-trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nixvim.url = "./modules/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    backups.url = "./modules/backups";
    backups.inputs.nixpkgs.follows = "nixpkgs";

    servers.url = "./modules/servers";
    servers.inputs.nixpkgs.follows = "nixpkgs";

    nixos.url = "./modules/nixos";
    nixos.inputs.nixpkgs.follows = "nixpkgs";

    ci.url = "./modules/ci";
    ci.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      mergeInputs = builtins.foldl' nixpkgs.lib.recursiveUpdate;
    in
    {
      nixosModules =
        with inputs;
        mergeInputs backups.nixosModules [
          servers.nixosModules
          nixos.nixosModules
        ];

      packages =
        nixpkgs.lib.recursiveUpdate
          (
            with inputs;
            mergeInputs backups.packages [
              ci.packages
              nixvim.packages
            ]
          )
          {
            x86_64-linux =
              let
                pkgs = nixpkgs.legacyPackages.x86_64-linux;
              in
              nixpkgs.lib.genAttrs
                [
                  "flaketex"
                  "jeniffer2"
                  "neural-pixel"
                  "sdcpp-webui"
                  "quick-template"
                  "scan-crop"
                ]
                (
                  name:
                  with pkgs;
                  with javaPackages;
                  with python3Packages;
                  callPackage (import ./derivations/${name}.nix) {
                    latex = texliveFull;
                    stable-diffusion-cpp = stable-diffusion-cpp-vulkan;
                  }
                )
              // {
                image-nvim = pkgs.luajitPackages.image-nvim;
                blackbox-terminal = pkgs.blackbox-terminal;
                stable-diffusion-cpp-vulkan = pkgs.stable-diffusion-cpp-vulkan;
              };
          };

      overlays =
        with inputs;
        mergeInputs
          (nixpkgs.lib.genAttrs [ "stable-diffusion-cpp" ] (
            name:
            ((import ./overlays/${name}.nix) {
              inherit inputs;
              inherit (nixpkgs) lib;
            })
          ))
          [
            backups.overlays
            nixos.overlays
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
              user.fullName = "Fabian Haas";
              nixpkgs.overlays = [
                (final: prev: {
                  quick-template = self.packages.${system}.quick-template;
                })
              ];
            }
          ];
        }
      );
    };
}
