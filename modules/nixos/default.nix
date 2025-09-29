{ ... }: {
  imports = [
    ./backups
    ./boot.nix
    ./desktop
    ./development
    ./localization.nix
    ./nix.nix
    ./permissions.nix
    ./server
    ./user.nix
    ./workplace-compliance.nix
    ./text-processing.nix
  ];
}
