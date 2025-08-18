{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./android.nix
    ./container.nix
    ./embedded.nix
    ./js.nix
    ./network.nix
    ./openjdk.nix
    ./vagrant.nix
  ];

  users.users.${config.user.name}.packages = with pkgs; [
    quick-template
  ];
}
