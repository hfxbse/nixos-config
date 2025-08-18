{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.development.container;
in
{
  options.development.container.enable = lib.mkEnableOption "container support";

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true; # https://github.com/nektos/act is not fully compatible with rootless docker
      storageDriver = lib.mkDefault "btrfs";
    };

    users.groups.docker.members = [ config.user.name ];

    users.users.${config.user.name}.packages = [ pkgs.docker-compose ];
  };
}
