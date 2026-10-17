{
  osConfig,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  cfg = config.applications.multimedia;
  allowUnfree = config.nixpkgs.config.allowUnfree or osConfig.nixpkgs.config.allowUnfree or false;
in
{
  options.applications.multimedia = {
    enable = lib.mkEnableOption "Whether to install audio streaming and video playback programs.";

    imageEditing.enable = lib.mkEnableOption "Whether to add bitmap and vector graphic editors" // {
      default = true;
    };

    videoRecording.enable = lib.mkEnableOption "Whether to install video recording tools.";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      lib.optional (!isDarwin) (with pkgs; vlc)
      ++ lib.optional allowUnfree pkgs.spotify
      ++ lib.optionals cfg.imageEditing.enable (
        lib.optional (!isDarwin) pkgs.gimp
        ++ (with pkgs; [
          darktable
          inkscape
        ])
      )
      ++ lib.optional cfg.videoRecording.enable pkgs.obs-studio;
  };
}
