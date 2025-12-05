{
  description = "Nixos configuration to manage my various system configs and derivations.";

  inputs = {
    nixpkgs.url = "github:Mic92/nixpkgs?ref=facter-camera";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      ownPackages =
        let
          packages = self.packages.${system};
          packageNames = builtins.filter (
            name: !(builtins.elem name (builtins.attrNames nixpkgs.legacyPackages.${system}))
          ) (builtins.attrNames packages);
        in
        (final: prev: lib.genAttrs packageNames (name: packages.${name}));

      overlays = [
        ownPackages
        ((import ./overrides.nix) lib)
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system} =
        lib.genAttrs [
          "flaketex"
          "cups-brother-hl3172cdw"
          "quick-template"
        ] (name: pkgs.callPackage (import ./derivations/${name}.nix) { latex = pkgs.texliveFull; })
        // {
          image-nvim = pkgs.luajitPackages.image-nvim;
          blackbox-terminal = pkgs.blackbox-terminal;
          nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
            inherit pkgs;
            module = ./modules/neovim/neovim.nix;
          };
        };

      templates = {
        default = self.templates.baseline;
        baseline = {
          description = "A baseline flake";
          path = ./templates/baseline;
        };
      };

      nixosConfigurations =
        let
          genericModules = [
            inputs.disko.nixosModules.disko
            inputs.nixos-wsl.nixosModules.default
            inputs.lanzaboote.nixosModules.lanzaboote
            nixvim.nixosModules.nixvim
            ./modules/nixos/default.nix
            {
              nixpkgs.overlays = overlays;
              user.fullName = "Fabian Haas";
            }
          ];

        in
        lib.genAttrs [ "ice-cube" "ice-skate" "snowman" "snowball" ] (
          name:
          lib.nixosSystem {
            inherit system;
            modules = genericModules ++ [
              ./hosts/${name}/configuration.nix
            ];
          }
        )
        // {
          iso = lib.nixosSystem {
            modules = genericModules ++ [
              {
                nixpkgs = {
                  inherit overlays;
                  hostPlatform = system;
                };
              }
              ./hosts/iso/configuration.nix
            ];
          };
        };
    };
}
