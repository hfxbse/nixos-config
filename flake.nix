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

    quick-template = {
      url = "github:hfxbse/nixos-config?ref=derivation/quick-template";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      disko,
      nixpkgs,
      nixvim,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = lib.genAttrs [
        "flaketex"
        "cups-brother-hl3172cdw"
      ] (name: pkgs.callPackage (import ./derivations/${name}.nix) { latex = pkgs.texliveFull; });

      nixosConfigurations =
        let
          fullName = {
            user.fullName = "Fabian Haas";
          };

          additionalPackages = with inputs; {
            quick-template = quick-template.packages.x86_64-linux.quick;
          };

          baseModules = name: [
            fullName
            nixvim.nixosModules.nixvim
            ./hosts/${name}/configuration.nix
            ./modules/permissions.nix
            ./modules/text-processing.nix
            {
              nixpkgs.overlays =
                let
                  packages = self.packages.${system};
                in
                [
                  (final: prev: lib.genAttrs (builtins.attrNames packages) (name: packages.${name}))
                ];
            }
          ];

          interactiveSystemModules =
            name:
            baseModules name
            ++ [
              ./modules/desktop/desktop.nix
              ./modules/development.nix
              ./modules/localization.nix
            ];

        in
        lib.genAttrs [ "home-pc" "nt-laptop" ] (
          name:
          lib.nixosSystem {
            inherit system;
            specialArgs = additionalPackages;
            modules = interactiveSystemModules name ++ [
              ./modules/printing.nix
              ./modules/workplace-compliance.nix
            ];
          }
        )
        // {
          cgi-wsl = lib.nixosSystem {
            inherit system;
            specialArgs = additionalPackages;
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
            modules = baseModules "server" ++ [
              disko.nixosModules.disko
            ];
          };
        };
    };
}
