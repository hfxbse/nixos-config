{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    inputs:
    let
      allowUnfree =
        system: pkgNames:
        import inputs.nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) pkgNames;
        };

      perSystem' =
        systems: generator:
        inputs.nixpkgs.lib.genAttrs systems (
          system: generator system (allowUnfree system [ "cups-brother-hl3172cdw" ])
        );

      genModule = imports: { inherit imports; };
      applyOverlays =
        module:
        inputs.nixpkgs.lib.recursiveUpdate module {
          nixpkgs.overlays = builtins.attrValues inputs.self.overlays;
        };
    in
    {
      darwinModules.applications = applyOverlays (genModule [ ./nixpkgs.nix ]);
      homeModules.applications = genModule [ ./applications ];
      nixosModules.applications = applyOverlays (genModule [ ./nixpkgs.nix ]);

      darwinModules.desktop-environments = genModule [ ./fonts/packages.nix ];
      homeModules.desktop-environments = genModule [ ./fonts/config.nix ];
      nixosModules.desktop-environments = applyOverlays (genModule [
        ./environment
        ./fonts
      ]);

      packages = perSystem' [ "x86_64-linux" ] (
        system: pkgs: {
          cups-brother-hl3172cdw = pkgs.callPackage (import ./derivations/cups-brother-hl3172cdw.nix) { };
        }
      );

      overlays.experimental-sane = import ./overlays/sane-backends.nix;
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
