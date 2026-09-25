{ pkgs, ... }:
{
  fonts.packages =
    with pkgs;
    [
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
    ]
    ++ (with nerd-fonts; [
      jetbrains-mono
      noto
    ]);
}
