{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      perSystem =
        generator:
        inputs.nixpkgs.lib.genAttrs [ "x86_64-linux" ] (
          system:
          generator system (
            import inputs.nixpkgs {
              inherit system;
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (inputs.nixpkgs.lib.getName pkg) [
                  "cups-brother-hl3172cdw"
                ];
            }
          )
        );
    in
    {
      nixosModules.nixos = {
        imports = [
          ./.
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.nixos-wsl.nixosModules.default
        ];

        nixpkgs.overlays = [
          inputs.nix-cachyos-kernel.overlays.pinned
          inputs.self.overlays.printer-drivers
        ];

        # CachyOS Kernel binary cache
        # See https://github.com/xddxdd/nix-cachyos-kernel?tab=readme-ov-file#binary-cache
        nix.settings = {
          substituters = [ "https://attic.xuyh0120.win/lantian" ];
          trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
        };
      };

      packages = perSystem (
        system: pkgs: {
          cups-brother-hl3172cdw = pkgs.callPackage (import ./derivations/cups-brother-hl3172cdw.nix) { };
        }
      );

      overlays.printer-drivers =
        final: prev:
        let
          packages = inputs.self.packages.${prev.stdenv.hostPlatform.system};
        in
        {
          inherit (packages) cups-brother-hl3172cdw;
        };
    };
}
