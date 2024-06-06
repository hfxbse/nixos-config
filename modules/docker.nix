{ pkgs, host, ... }: {
  virtualisation.docker = {
    enable = true;    # Not rootless as https://github.com/nektos/act is not fully compatible with it
    storageDriver = "btrfs";
  };

  users.users.${host.user.name} = {
    extraGroups = [ "docker" ];
    packages = with pkgs; [ docker-compose ];
  };
}
