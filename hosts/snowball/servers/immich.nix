{
  config,
  lib,
  pkgs,
  ...
}:
let
  immichVolumes = [
    "/mnt/immich/memory-card"
    "/mnt/immich/usb-drive"
    "/mnt/immich/boot-drive"
  ];

  secretsFiles =
    subDir: properties:
    lib.pipe properties [
      (map (name: "${name}File"))
      (lib.flip lib.genAttrs (
        property: "/var/lib/secrets/immich/${subDir}/${lib.removeSuffix "File" property}"
      ))
    ];
in
{

  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
  ];

  backups.volumePaths = immichVolumes;
  fileSystems."/var/lib/immich/media" = {
    depends = immichVolumes;
    device = "/mnt/immich/*";
    fsType = "mergerfs";
    options = [
      "defaults"
      "fsname=mergerfs-immich"
    ];
  };

  # FUSE based like mergerfs directores do not support id mapping permissions
  containers.gallery.privateUsers = "identity";
  server.containers.gallery.dataDirs.media.idmap = false;
  users =
    with config.containers.gallery.config;
    let
      inherit (services.immich) group user;
      inherit (users.users.${user}) uid;
      inherit (users.groups.${group}) gid;
    in
    {
      users.${user} = {
        inherit uid;
        group = services.immich.group;
        isSystemUser = true;
      };
      groups.${group}.gid = gid;
    };

  server.services.gallery = {
    enable = true;
    dataDir = "/var/lib/immich";
    domain = "gallery.fxbse.com";

    oauth = secretsFiles "oauth" [
      "clientId"
      "clientSecret"
      "issuerUrl"
    ];

    smtp =
      (secretsFiles "notifications/smtp" [
        "host"
        "password"
        "username"
      ])
      // {
        port = 465;
      };
  };
}
