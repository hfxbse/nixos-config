{
  description = "Nixos configuration to manage my various system configs and derivations.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
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
        in
        (final: prev: lib.genAttrs (builtins.attrNames packages) (name: packages.${name}));

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ ownPackages ];
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
          nixvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
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
          fullName = {
            user.fullName = "Fabian Haas";
          };

          baseModules = name: [
            fullName
            inputs.disko.nixosModules.disko
            inputs.nixos-facter-modules.nixosModules.facter
            nixvim.nixosModules.nixvim
            ./hosts/${name}/configuration.nix
            ./modules/nixos/nix.nix
            ./modules/nixos/permissions.nix
            ./modules/nixos/text-processing.nix
            {
              nixpkgs.overlays = [ ownPackages ];
            }
          ];

          interactiveSystemModules =
            name:
            baseModules name
            ++ [
              ./modules/nixos/desktop/desktop.nix
              ./modules/nixos/development.nix
              ./modules/nixos/localization.nix
            ];
        in
        lib.genAttrs [ "home-pc" "nt-laptop" "uni-tablet" ] (
          name:
          lib.nixosSystem {
            inherit system;
            modules = interactiveSystemModules name ++ [
              ./modules/nixos/printing.nix
              ./modules/nixos/workplace-compliance.nix
            ];
          }
        )
        // {
          cgi-wsl = lib.nixosSystem {
            inherit system;
            modules = interactiveSystemModules "cgi-wsl" ++ [
              inputs.nixos-wsl.nixosModules.default
            ];
          };

          iso = lib.nixosSystem {
            # Set wifi and ssh key via the setup options defined in the configuration file
            modules = baseModules "iso";
          };

          server = lib.nixosSystem {
            inherit system;
            modules = baseModules "server";
          };
        };
    };
}
