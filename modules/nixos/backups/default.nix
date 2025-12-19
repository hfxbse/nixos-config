{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.backups;
  snapshotter = lib.getExe pkgs.by-disk-snapshotter;
in
{
  options.backups = {
    enable = lib.mkEnableOption "automatic backups";

    cpuLimit = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      description = "Limit how many CPU cores are used in parallel.";
      default = null;
    };

    repository = {
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the file containing the repository password.";
      };

      urlFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the file containig the URL to the backup repository.
          Neccessary as the URL may contain the credentials.
        '';
      };
    };

    volumePaths = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = "Absolute paths to the backup roots.";
    };

    snapshotPath = lib.mkOption {
      type = lib.types.path;
      default = "/snapshots";
    };
  };

  config.services.restic.backups =
    let
      environment = "${pkgs.writeText "restic-environment" ''
        GOMAXPROCS=${builtins.toString cfg.cpuLimit}
      ''}";

      paths = lib.concatStringsSep " " cfg.volumePaths;
      backupPrepareCommand = "${snapshotter} ${cfg.snapshotPath} ${paths};";
      backupCleanupCommand = "${snapshotter} -c ${cfg.snapshotPath} ${paths};";
    in
    lib.mkIf cfg.enable {
      borgbase = {
        inherit backupPrepareCommand backupCleanupCommand;

        initialize = true;
        repositoryFile = cfg.repository.urlFile;
        passwordFile = cfg.repository.passwordFile;

        paths = [ cfg.snapshotPath ];
        environmentFile = lib.mkIf (cfg.cpuLimit != null) environment;

        exclude = lib.map (path: "*${path}") (
          with cfg.repository;
          [
            urlFile
            passwordFile
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
