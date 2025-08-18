{ ... }: {
  imports = [
    ./boot.nix
    ./desktop
    ./development
    ./localization.nix
    ./nix.nix
    ./permissions.nix
    ./user.nix
    ./workplace-compliance.nix
    ./text-processing.nix
  ];
}
