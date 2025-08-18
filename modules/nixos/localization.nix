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

  config.console.keyMap = lib.mkIf cfg.enable "de";
  config.time.timeZone = lib.mkIf cfg.enable (lib.mkDefault "Europe/Berlin");
  config.i18n = lib.mkIf cfg.enable {
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
  config.services.xserver.xkb = lib.mkIf (cfg.enable && config.desktop.enable) {
    layout = "de";
    variant = "";
  };
}
