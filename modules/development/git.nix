{
  config,
  lib,
  pkgs,
  ...
}:
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
      diff.external = lib.getExe pkgs.difftastic;
      init.defaultBranch = "main";
      interactive.diffFilter = "${lib.getExe pkgs.diff-so-fancy} --patch";
      pull.rebase = true;
      user.name = cfg.user.fullName;
    };
  };
}
