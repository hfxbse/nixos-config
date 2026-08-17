{
  config,
  lib,
  pkgs,
  ...
}:
{
  config =
    {
      programs.bash.interactiveShellInit = ''
        set -o vi

        HISTSIZE=5000
        HISTFILESIZE=15000
      '';


      fonts.packages = lib.mkIf config.desktop.enable (
        with pkgs;
        [
          nerd-fonts.jetbrains-mono
        ]
      );
    };
}
