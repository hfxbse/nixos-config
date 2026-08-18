{
  description = "Nixos configuration to manage my various system configs and derivations.";

  nixConfig = {
    # CachyOS Kernel binary cache
    # See https://github.com/xddxdd/nix-cachyos-kernel?tab=readme-ov-file#binary-cache
    extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
    extra-trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-container-in-vm-fix = {
      url = "github:hfxbse/nixpkgs?ref=nixos-container-inside-vm-fix";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    nix-minecraft.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    flake-compat.url = "github:edolstra/flake-compat";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      home-manager,
      nixpkgs,
      nixvim,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      ownPackages =
        { system }:
        let
          packages = self.packages.${system};
          packageNames = builtins.filter (
            name: !(builtins.elem name (builtins.attrNames nixpkgs.legacyPackages.${system}))
          ) (builtins.attrNames packages);
        in
        (final: prev: lib.genAttrs packageNames (name: packages.${name}));

      overlays = builtins.attrValues self.overlays ++ [
        (ownPackages { inherit system; })
        inputs.nix-cachyos-kernel.overlays.pinned
        inputs.nix-minecraft.overlay
      ];

      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      genericModules = [
        inputs.disko.nixosModules.disko
        inputs.nixos-wsl.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.nix-minecraft.nixosModules.minecraft-servers
        "${inputs.nixpkgs-container-in-vm-fix}/nixos/modules/virtualisation/nixos-containers.nix"
        ./modules/nixos/default.nix
        {
          # Container in VM fix
          # See https://discourse.nixos.org/t/using-changes-from-a-nixpkgs-pr-in-your-flake/60948
          disabledModules = [ "virtualisation/nixos-containers.nix" ];

          nixpkgs.overlays = overlays;
          user.fullName = "Fabian Haas";
        }
        {
          nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
          nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
        }
      ];
    in
    {
      packages.aarch64-darwin = {
        nvim = nixvim.legacyPackages.aarch64-darwin.makeNixvimWithModule {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          module = ./modules/nixvim;
        };
      };

      packages.${system} =
        lib.genAttrs
          [
            "by-disk-snapshotter"
            "ci-version-checker"
            "cups-brother-hl3172cdw"
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
          nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
            inherit pkgs;
            module = ./modules/nixvim;
          };
          stable-diffusion-cpp-vulkan = pkgs.stable-diffusion-cpp-vulkan;
        };

      overlays = lib.genAttrs [
        "beszel"
        "image-nvim"
        "stable-diffusion-cpp"
      ] (name: ((import ./overlays/${name}.nix) { inherit inputs lib; }));

      devShells.${system} = {
        sbom = pkgs.mkShell {
          packages = with pkgs; [
            sbomnix
          ];
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
        lib.genAttrs [ "ice-skate" "snowball" ] (
          name:
          lib.nixosSystem {
            specialArgs = { inherit inputs; };
            inherit system;
            modules = genericModules ++ [
              nixvim.nixosModules.nixvim
              home-manager.nixosModules.home-manager
              ./modules/generic
              ./modules/home-manager
              ./modules/nixvim/module.nix
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
              nixvim.nixosModules.nixvim
              home-manager.nixosModules.home-manager
              ./modules/generic
              ./modules/home-manager
              ./modules/nixvim/module.nix
              ./hosts/iso/configuration.nix
            ];
          };
        };

      darwinConfigurations."MN-EXM79RNYVFQ1" = inputs.nix-darwin.lib.darwinSystem {
        modules = [
          {
            nixpkgs.overlays = overlays ++ [
              (ownPackages { system = "aarch64-darwin"; })
            ];
          }
          nixvim.nixDarwinModules.nixvim
          home-manager.darwinModules.home-manager
          ./modules/generic
          ./modules/darwin
          ./modules/home-manager
          ./modules/nixvim/module.nix
          ./hosts/MN-EXM79RNYVFQ1/configuration.nix
        ];
      };
    };
}
