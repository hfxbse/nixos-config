{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.multimedia;
  user = config.user;
in
{
  options.desktop.multimedia = {
    enable = lib.mkEnableOption "audio streaming and video playback programs" // {
      default = config.desktop.enable;
    };

    imageEditing.enable = lib.mkEnableOption "bitmap and vector graphic editors" // {
      default = true;
    };

    videoRecording.enable = lib.mkEnableOption "video recording tools";
  };

  config = lib.mkIf cfg.enable {
    users.users.${user.name}.packages =
      with pkgs;
      [ vlc ]
      ++ lib.optional config.nixpkgs.config.allowUnfree pkgs.spotify
      ++ lib.optionals cfg.imageEditing.enable (
        with pkgs;
        [
          gimp
          inkscape
        ]
      )
      ++ lib.optional cfg.videoRecording.enable pkgs.obs-studio;
  };
}
