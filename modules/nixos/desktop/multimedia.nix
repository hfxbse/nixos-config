{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.multimedia;
  user = config.user;
in
{
  options.multimedia = {
    enable = lib.mkEnableOption "audio streaming and video playback programs";

    imageEditing.enable = lib.mkOption {
      description = "bitmap and vector graphic editors";
      type = lib.types.bool;
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
