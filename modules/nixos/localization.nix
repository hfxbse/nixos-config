{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = lib.mkIf config.desktop.enable {
    layout = "de";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  fonts = {
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
