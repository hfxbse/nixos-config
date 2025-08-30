{ ... }: {
  imports = [
    ./backups
    ./boot.nix
    ./desktop
    ./development
    ./localization.nix
    ./nix.nix
    ./permissions.nix
    ./user.nix
    ./windscribe.nix
    ./workplace-compliance.nix
    ./text-processing.nix
  ];
}
