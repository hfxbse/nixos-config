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

  config =
    {
      programs.nixvim.enable = true;
      programs.bash.interactiveShellInit = ''
        set -o vi

        HISTSIZE=5000
        HISTFILESIZE=15000
      '';

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
