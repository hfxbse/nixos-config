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
  };

  outputs = { self, cups-brother-hl3172cdw, disko, nixpkgs, nixvim }@attrs:
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
      ./modules/localization.nix
      ./modules/text-processing.nix
      ./modules/workplace-compliance.nix
      ./modules/printing.nix
      ./modules/development.nix
    ];
  in
  {
    nixosConfigurations.home-pc = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; {
        cups-brother-hl3172cdw = cups-brother-hl3172cdw.packages.x86_64-linux.default;
      };

      system = "x86_64-linux";
      modules = defaultModules ++ [ ./hosts/home-pc/configuration.nix ];
    };

    nixosConfigurations.nt-laptop = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; {
        cups-brother-hl3172cdw = cups-brother-hl3172cdw.packages.x86_64-linux.default;
      };

      system = "x86_64-linux";
      modules = defaultModules ++ [ ./hosts/nt-laptop/configuration.nix ];
    };

    nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; {
        # TODO add your WiFi credentials
        # wifi.ssid
        # wifi.psk
      };

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
