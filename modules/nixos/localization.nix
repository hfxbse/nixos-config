{
  config,
  lib,
  ...
}:
let
  cfg = config.localization;
in
{
  options.localization.enable = lib.mkEnableOption "English as language but German formatting." // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    console.keyMap = "de";
    time.timeZone = lib.mkDefault "Europe/Berlin";
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
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
    };

    # Configure keymap in X11
    services.xserver.xkb = lib.mkIf config.desktop.enable {
      layout = "de";
      variant = "";
    };
  };
}
