{ lib, pkgs, ... }:
let
  histSize = 5000;
  viMode = ''
    set -o vi
  '';
in
{
  programs = {
    bash.interactiveShellInit = viMode + ''
      HISTSIZE=${toString histSize}
      HISTFILESIZE=${toString (3 * histSize)}
    '';

    zsh = {
      histSize = histSize;
      interactiveShellInit =
        viMode
        + (lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          ssh-add --apple-load-keychain
        '');
    };
  };
}
