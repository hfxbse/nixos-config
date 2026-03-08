{
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
      }
    ;
  };
}
