{
  description = "Nixos configuration to manage my computer at home and my work laptop.";

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

    cups-brother-hl3172cdw = {
      url = "github:hfxbse/nixos-config?ref=derivation/cups-brother-hl3172cdw";
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

  outputs = { self, disko, nixpkgs, nixvim, ... }@attrs:
  let
    fullName = {
      user.fullName = "Fabian Haas";
    };

    defaultModules = [
      fullName
      # Nixvim needs to be an top level import
      # Will fail due to infinit recursion otherwise
      nixvim.nixosModules.nixvim
      disko.nixosModules.disko
      ./modules/desktop/desktop.nix
      ./modules/development.nix
      ./modules/localization.nix
      ./modules/printing.nix
      ./modules/permissions.nix
      ./modules/text-processing.nix
      ./modules/workplace-compliance.nix
    ];

    additionalPackages = with attrs; {
        cups-brother-hl3172cdw = cups-brother-hl3172cdw.packages.x86_64-linux.default;
        quick-template = quick-template.packages.x86_64-linux.quick;
    };
  in
  {
    nixosConfigurations.home-pc = nixpkgs.lib.nixosSystem {
      specialArgs = additionalPackages;
      system = "x86_64-linux";
      modules = defaultModules ++ [ ./hosts/home-pc/configuration.nix ];
    };

    nixosConfigurations.nt-laptop = nixpkgs.lib.nixosSystem {
      specialArgs = additionalPackages;
      system = "x86_64-linux";
      modules = defaultModules ++ [ ./hosts/nt-laptop/configuration.nix ];
    };

    nixosConfigurations.cgi-wsl = nixpkgs.lib.nixosSystem {
      specialArgs = additionalPackages;
      system = "x86_64-linux";
      modules = [
        fullName
        attrs.nixos-wsl.nixosModules.default
        nixvim.nixosModules.nixvim
        ./modules/localization.nix
        ./modules/desktop/desktop.nix
        ./modules/development.nix
        ./modules/permissions.nix
        ./modules/text-processing.nix
        ./hosts/cgi-wsl/configuration.nix
      ];
    };

    nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
      # Set wifi and ssh key via the setup options defined in the configuration file
      modules = [
       fullName
       nixvim.nixosModules.nixvim
       ./modules/text-processing.nix
       ./hosts/iso/configuration.nix
      ];
    };

    nixosConfigurations.server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        fullName
        nixvim.nixosModules.nixvim
        disko.nixosModules.disko
        ./modules/text-processing.nix
        ./hosts/server/configuration.nix
      ];
    };
  };
}
