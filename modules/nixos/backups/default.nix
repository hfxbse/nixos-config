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

      cpuLimit = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        description = "Limit how many CPU cores are used in parallel.";
        default = null;
      };

      repositoryPasswordFile = lib.mkOption {
        type = absolutePathString;
        description = "Path to the file containing the repository password.";
      };

      repositoryUrlFile = lib.mkOption {
        type = absolutePathString;
        description = ''
          Path to the file containig the URL to the backup repository.
          Neccessary as the URL may contain the credentials.
        '';
      };

      rootPaths = lib.mkOption {
        type = lib.types.listOf absolutePathString;
        description = "Absolute paths to the backup roots.";
      };
    };

  config.services.restic.backups =
    let
      environment = "${pkgs.writeText "restic-environment" ''
        GOMAXPROCS=${builtins.toString cfg.cpuLimit}
      ''}";

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

        initialize = true;
        repositoryFile = cfg.repositoryUrlFile;
        passwordFile = cfg.repositoryPasswordFile;

        paths = [ "/snapshots" ];
        environmentFile = lib.mkIf (cfg.cpuLimit != null) environment;

        exclude = lib.map (path: "*${path}") (
          with cfg;
          [
            repositoryUrlFile
            repositoryPasswordFile
          ]
        );

        extraBackupArgs = [
          "--compression=max"
          "--exclude-caches"
          "--exclude-file=${./exclude.txt}"
        ];
      };
    };
}
