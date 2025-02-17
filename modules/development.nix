{ config, lib, pkgs, ... }:
let
  cfg = config.development;
  username = config.user.name;
in
{
  imports = [ ./vagrant.nix ];

  options.development = {
    android.enable = lib.mkEnableOption "Android development support";
    container.enable = lib.mkEnableOption "container support";
    embedded.enable = lib.mkEnableOption "embedded development support";
    js.enable = lib.mkEnableOption "JavaScript development support";
    openjdk.enable = lib.mkEnableOption "OpenJDK development support";
  };

  config = {
    virtualisation.docker = lib.mkIf cfg.container.enable {
      enable = true;    # https://github.com/nektos/act is not fully compatible with rootless docker
      storageDriver = "btrfs";
    };

    programs.adb.enable = cfg.android.enable;
    programs.nix-ld = {
      # Some NPM packages contain unpatched binaries, for example Cloudflare's Wrangler CLI
      enable = lib.mkDefault (cfg.openjdk.enable || cfg.js.enable);

      libraries = lib.optionals cfg.openjdk.enable (with pkgs; [
        gtk3
        gdk-pixbuf
        xorg.libXtst
        xorg.libXxf86vm
        xorg.libX11
        glib
        cairo
        pango
        libGL
      ]);
    };

    services.gvfs.enable = lib.mkDefault cfg.android.enable;
    services.udev.packages =
      lib.optional cfg.android.enable pkgs.android-udev-rules ++
      lib.optional cfg.embedded.enable pkgs.platformio-core.udev;

    users.groups.adbuser.members = lib.optional cfg.android.enable username;
    users.groups.dialout.members = lib.optional cfg.embedded.enable username;  # Non-root access to serial ports
    users.groups.docker.members = lib.optional cfg.container.enable username;

    users.users.${username}.packages = lib.optional cfg.container.enable pkgs.docker-compose;

    development.vagrant.user = lib.mkDefault username;
  };
}
