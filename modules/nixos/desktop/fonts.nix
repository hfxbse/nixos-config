{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop;
in
{
  # Set a default font that supports multiple charsets
  config.fonts = lib.mkIf cfg.enable {
    packages =
      with pkgs;
      [
        noto-fonts
        noto-fonts-emoji
        noto-fonts-cjk-sans
      ]
      ++ (with pkgs.nerd-fonts; [
        jetbrains-mono
        noto
      ]);

    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrainsMonoNerdFontMono" ];
      };
    };
  };
}
