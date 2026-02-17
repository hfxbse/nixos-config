{
  description = "Nixos configuration to manage my various system configs and derivations.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-container-in-vm-fix = {
      url = "github:hfxbse/nixpkgs?ref=nixos-container-inside-vm-fix";
    };

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
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

      overlays = builtins.attrValues self.overlays ++ [
        ownPackages
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system} =
        lib.genAttrs
          [
            "by-disk-snapshotter"
            "cups-brother-hl3172cdw"
            "flaketex"
            "jeniffer2"
            "quick-template"
          ]
          (
            name:
            with pkgs;
            with javaPackages;
            callPackage (import ./derivations/${name}.nix) { latex = texliveFull; }
          )
        // {
          image-nvim = pkgs.luajitPackages.image-nvim;
          blackbox-terminal = pkgs.blackbox-terminal;
          nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
            inherit pkgs;
            module = ./modules/neovim/neovim.nix;
          };
        };

      overlays = lib.genAttrs [
        "image-nvim"
        "sieve-editor-gui"
      ] (name: ((import ./overlays/${name}.nix) { inherit inputs lib; }));

      devShells.${system} = {
        sbom = pkgs.mkShell { packages = with pkgs; [ sbomnix ]; };
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
            inputs.nixos-facter-modules.nixosModules.facter
            inputs.nixos-wsl.nixosModules.default
            inputs.lanzaboote.nixosModules.lanzaboote
            nixvim.nixosModules.nixvim
            "${inputs.nixpkgs-container-in-vm-fix}/nixos/modules/virtualisation/nixos-containers.nix"
            ./modules/nixos/default.nix
            {
              # See https://discourse.nixos.org/t/using-changes-from-a-nixpkgs-pr-in-your-flake/60948
              disabledModules = [ "virtualisation/nixos-containers.nix" ];

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
