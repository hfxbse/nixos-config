{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.user.fullName = lib.mkOption {
    description = "The full name of the user of the machine";
    type = lib.types.str;
  };

  config = {
    programs.git.enable = true;
    programs.git.config = {
      init.defaultBranch = "main";
      user.name = config.user.fullName;
      pull.rebase = true;
    };

    fonts.packages = lib.mkIf config.desktop.enable (
      with pkgs;
      [
        nerd-fonts.jetbrains-mono
      ]
    );
  };
}
