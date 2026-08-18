{
  config,
  lib,
  pkgs,
  ...
}:
let

  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
  cfg = config.multimedia;
  user = config.user;

  packages =
    lib.optional isLinux pkgs.vlc
    ++ lib.optional (config.nixpkgs.config.allowUnfree or false) pkgs.spotify
    ++ lib.optionals cfg.imageEditing.enable (
      with pkgs;
      [
        darktable
        # See https://github.com/NixOS/nixpkgs/pull/513484
        (if isLinux then gimp else gimp2)

        # Broken on aarch64-darwin
        # See https://github.com/NixOS/nixpkgs/issues/383860
        inkscape
      ]
    )
    ++ lib.optional cfg.videoRecording.enable pkgs.obs-studio;
in
{
  options.multimedia = {
    enable = lib.mkEnableOption "audio streaming and video playback programs";

    imageEditing.enable = lib.mkEnableOption "bitmap and vector graphic editors" // {
      default = true;
    };

    videoRecording.enable = lib.mkEnableOption "video recording tools";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optionals isLinux (
        # Thumbnailers
        # See https://wiki.nixos.org/wiki/Thumbnails
        (with pkgs;
        [
          ffmpeg-headless
          ffmpegthumbnailer

          gdk-pixbuf

          libheif
          libheif.out
        ])
      )
      # See https://github.com/nix-darwin/nix-darwin/issues/139
      ++ lib.optionals isDarwin packages;
    users.users.${user.name}.packages = lib.mkIf isLinux packages;
  };
}
