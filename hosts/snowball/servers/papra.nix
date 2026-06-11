{
  config,
  pkgs,
  ...
}:
let
  papraVolumes = [
    "/mnt/papra/memory-card"
    "/mnt/papra/usb-drive"
    "/mnt/papra/boot-drive"
  ];
in
{
  environment.systemPackages = with pkgs; [
    mergerfs
    mergerfs-tools
  ];

  backups.volumePaths = papraVolumes;
  fileSystems."/var/lib/papra/local-documents" = {
    depends = papraVolumes;
    device = "/mnt/papra/*";
    fsType = "mergerfs";
    options = [
      "defaults"
      "fsname=mergerfs-papra"
    ];
  };

  # FUSE based like mergerfs directores do not support id mapping permissions
  containers.doc-management.privateUsers = "identity";
  server.containers.doc-management.dataDirs.papra.idmap = false;
  users =
    with config.containers.doc-management.config;
    let
      inherit (services.papra) group user;
      inherit (users.users.${user}) uid;
      inherit (users.groups.${group}) gid;
    in
    {
      users.${user} = {
        inherit uid group;
        isSystemUser = true;
      };
      groups.${group}.gid = gid;
    };

  server.services.document-management = {
    enable = true;
    dataDir = "/var/lib/papra";
    domain = "documents.fxbse.com";
    environmentFile = "/var/lib/secrets/papra.env";
  };
}
