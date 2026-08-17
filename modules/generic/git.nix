{
  config,
  lib,
  pkgs,
  ...
}:
with pkgs.stdenv.hostPlatform;
{
  options = {
    user.fullName = lib.mkOption {
      description = "The full name of the user of the machine";
      type = lib.types.str;
    };
  };

  config.programs = lib.mkIf isLinux {
    git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        user.name = config.user.fullName;
        pull.rebase = true;
      };
    };
  };
}
