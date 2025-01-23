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
    defaultModules = [
      # Nixvim needs to be an top level import
      # Will fail due to infinit recursion otherwise
      nixvim.nixosModules.nixvim
      disko.nixosModules.disko
      ./modules/desktop/desktop.nix
      ./modules/localization.nix
      ./modules/text-processing.nix
      ./modules/workplace-compliance.nix
      ./modules/printing.nix
      ./modules/hardware/Wooting/wootility.nix
      ./modules/development.nix
    ];
  in
  {
    nixosConfigurations.home-pc = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; {
        cups-brother-hl3172cdw = cups-brother-hl3172cdw.packages.x86_64-linux.default;
        host = {
          user.name = "fxbse";
          user.description = "Fabian Haas";
          name = "ice-cube";
        };
      };

      system = "x86_64-linux";
      modules = defaultModules ++ [ ./hosts/home-pc/configuration.nix ];
    };

    nixosConfigurations.nt-laptop = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; {
        cups-brother-hl3172cdw = cups-brother-hl3172cdw.packages.x86_64-linux.default;
        host = rec {
          user.name = "fhs";
          user.description = "Fabian Haas";
          name = "nt-${user.name}";
        };
      };

      system = "x86_64-linux";
      modules = defaultModules ++ [ ./hosts/nt-laptop/configuration.nix ];
    };

    nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; {
        host.user.description = "Fabian Haas";

        # TODO add your WiFi credentials
        # wifi.ssid
        # wifi.psk
      };

      modules = [
       nixvim.nixosModules.nixvim
       ./modules/text-processing.nix
       ./hosts/iso/configuration.nix
      ];
    };

    nixosConfigurations.server = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; {
        host.user.description = "Fabian Haas";
      };

      system = "x86_64-linux";
      modules = [
        nixvim.nixosModules.nixvim
        disko.nixosModules.disko
        ./modules/text-processing.nix
        ./hosts/server/configuration.nix
      ];
    };
  };
}
