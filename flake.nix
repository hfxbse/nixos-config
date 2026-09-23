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

    nixvim.url = "./modules/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    backups.url = "./modules/backups";
    backups.inputs.nixpkgs.follows = "nixpkgs";

    servers.url = "./modules/servers";
    servers.inputs.nixpkgs.follows = "nixpkgs";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    {
      self,
      nixpkgs,
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
      nixosModules = inputs.backups.nixosModules // inputs.servers.nixosModules;
      packages.aarch64-darwin = inputs.nixvim.packages.aarch64-darwin;

      packages.${system} =
        lib.genAttrs
          [
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
          stable-diffusion-cpp-vulkan = pkgs.stable-diffusion-cpp-vulkan;
        }
        // inputs.backups.packages.${system}
        // inputs.nixvim.packages.${system};

      overlays =
        (lib.genAttrs [
          "beszel"
          "image-nvim"
          "stable-diffusion-cpp"
        ] (name: ((import ./overlays/${name}.nix) { inherit inputs lib; })))
        // inputs.backups.overlays
        // inputs.servers.overlays;

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
        let
          genericModules = [
            self.nixosModules.restic-backups
            self.nixosModules.servers
            inputs.disko.nixosModules.disko
            inputs.nixos-wsl.nixosModules.default
            inputs.lanzaboote.nixosModules.lanzaboote
            ./modules/nixos/default.nix
            {
              nixpkgs.overlays = overlays;
              user.fullName = "Fabian Haas";
            }
            {
              nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
              nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
            }
          ];

        in
        lib.genAttrs [ "ice-skate" "snowball" "geras" ] (
          name:
          lib.nixosSystem {
            specialArgs = { inherit inputs; };
            inherit system;
            modules = genericModules ++ [
              ./hosts/${name}/configuration.nix
            ];
          }
        );
    };
}
