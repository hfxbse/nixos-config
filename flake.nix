{
  description = "Nixos configuration to manage my various system configs and derivations.";

  nixConfig = {
    # CachyOS Kernel binary cache
    # See https://github.com/xddxdd/nix-cachyos-kernel?tab=readme-ov-file#binary-cache
    extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
    extra-trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };

  inputs = {
    nixpkgs-25-11.url = "github:nixos/nixpkgs?ref=nixos-25.11-small";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-container-in-vm-fix = {
      url = "github:hfxbse/nixpkgs?ref=nixos-container-inside-vm-fix";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

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
        inputs.nix-cachyos-kernel.overlays.pinned
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
            "ollamadiffuser"
            "sd-cpp-webui"
            "quick-template"
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
              # Container in VM fix
              # See https://discourse.nixos.org/t/using-changes-from-a-nixpkgs-pr-in-your-flake/60948
              disabledModules = [ "virtualisation/nixos-containers.nix" ];

              nixpkgs.overlays = overlays;
              user.fullName = "Fabian Haas";
            }
          ];

        in
        lib.genAttrs [ "ice-skate" "snowman" "snowball" ] (
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
