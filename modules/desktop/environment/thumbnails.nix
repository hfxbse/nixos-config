{ pkgs, ... }:
{
  # See https://wiki.nixos.org/wiki/Thumbnails
  environment.systemPackages = with pkgs; [
    ffmpeg-headless
    ffmpegthumbnailer

    gdk-pixbuf

    libheif
    libheif.out
  ];
}
