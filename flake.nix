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
  };

  outputs = { self, nixpkgs, nixvim, disko }@attrs:
  let
    defaultModules = [
      # Nixvim needs to be an top level import
      # Will fail due to infinit recursion otherwise
      nixvim.nixosModules.nixvim
      disko.nixosModules.disko
      ./modules/gnome.nix
      ./modules/networking.nix
      ./modules/localization.nix
      ./modules/text-processing.nix
      ./modules/docker.nix
      ./modules/security.nix
      ./hardware/Wooting/wootility.nix
    ];
  in
  {
    nixosConfigurations.home-pc = nixpkgs.lib.nixosSystem {
      specialArgs = with attrs; {
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
