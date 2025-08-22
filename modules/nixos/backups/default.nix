{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.backups;

  btrfsCli = lib.getExe pkgs.btrfs-progs;
in
{
  options.backups =
    let
      absolutePathString = lib.types.strMatching "^/.*";
    in
    {
      enable = lib.mkEnableOption "automatic backups";

      repositoryPasswordFile = lib.mkOption {
        type = absolutePathString;
        description = "Path to the file containing the repository password";
      };

      repositoryUrl = lib.mkOption {
        type = lib.types.str;
        description = "The URL to the backup repository";
      };

      rootPaths = lib.mkOption {
        type = lib.types.listOf absolutePathString;
        description = "Absolute paths to the backup roots";
      };
    };

  config.services.restic.backups =
    let
      backupPrepareCommand = ''
        set -e;
        mkdir /snapshots;

        for volumne in ${builtins.concatStringsSep " " cfg.rootPaths}; do
          echo $volumne;
          ${btrfsCli} subvolume snapshot -r "$volumne" "/snapshots$volumne";
        done
      '';
      backupCleanupCommand = ''
        set -e;
        ${btrfsCli} subvolume delete /snapshots/*
        rmdir /snapshots
      '';
    in
    lib.mkIf cfg.enable {
      borgbase = {
        inherit backupPrepareCommand backupCleanupCommand;

        repository = cfg.repositoryUrl;
        initialize = true;
        passwordFile = cfg.repositoryPasswordFile;

        paths = [ "/snapshots" ];
        exclude = [ cfg.repositoryPasswordFile ];
        extraBackupArgs = [
          "--exclude-caches"
          "--exclude-file=${./exclude.txt}"
        ];
      };
    };
}
