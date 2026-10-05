{ config, lib, ... }:
let
  cfg = config.development;
in
{
  options.development.user.fullName = lib.mkOption {
    description = "The full name of the developer.";
    type = lib.types.str;
  };

  config.programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      user.name = cfg.user.fullName;
      pull.rebase = true;
    };
  };
}
