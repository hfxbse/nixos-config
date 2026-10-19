{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.development;
  difft = lib.getExe pkgs.difftastic;
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
      interactive.diffFilter = "${lib.getExe pkgs.diff-so-fancy} --patch";
      pull.rebase = true;
      user.name = cfg.user.fullName;
      alias = {
        dl = "-c diff.external=${difft} log -p --ext-diff";
        ds = "-c diff.external=${difft} show --ext-diff";
        df = "-c diff.external=${difft} diff";
      };
    };
  };
}
