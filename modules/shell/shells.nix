let
  historySize = 10000;
  commonInit = ''
    set -o vi
  '';
in
{
  programs = {
    bash = {
      interactiveShellInit = commonInit + ''
        export HISTSIZE=${toString historySize}
        export HISTFILESIZE=${toString historySize}
      '';
    };

    zsh = {
      interactiveShellInit = commonInit;
      histSize = historySize;
    };
  };
}
