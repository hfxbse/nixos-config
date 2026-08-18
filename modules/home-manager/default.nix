{
  config,
  ...
}:
let
  user = config.user.name;
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users."${user}" = ./home.nix;
  };
}
