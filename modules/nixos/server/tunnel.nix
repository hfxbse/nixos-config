{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.tunnel;
in
{
  options.server.tunnel = {
    enable = lib.mkEnableOption "a tunnel to the internet in a container";

    environmentFile = lib.mkOption {
      type = lib.types.path;
    };

    systemStateVersion = lib.mkOption {
      description = "System state version used for the container. Do not change it after the container has been created.";
      type = lib.types.str;
    };
  };

  config = lib.mkIf (config.server.enable && cfg.enable) {
    server.network.tunnel = {
      subnetPrefix = "10.0.250";
      internetAccess = true;
    };

    containers.tunnel =
      let
        mountPath = "/run/secrets/tunnel.secrets";
      in
      {
        autoStart = true;
        privateUsers = "pick";

        bindMounts.tunnel-secrets = {
          mountPoint = "${mountPath}:idmap";
          hostPath = cfg.environmentFile;
          isReadOnly = true;
        };

        config = {
          systemd.services.tls-tunnel = {
            description = "Tunnels traffic from the internet to the reverse proxy";
            wantedBy = [ "multi-user.target" ];

            serviceConfig = rec {
              RuntimeDirectory = "tunnel";
              EnvironmentFile = mountPath;
              Restart = "always";
              RestartSec = "3s";
              RestartSteps = 10;
              RestartMaxDelaySec = "5min";

              ExecStartPre = lib.concatStringsSep " " [
                "${pkgs.openssh}/bin/ssh-keygen"
                "-q"
                "-f /run/${RuntimeDirectory}/id"
                "-t ed25519"
                ''-N \"\"''
              ];

              ExecStart = lib.concatStringsSep " " [
                (lib.getExe pkgs.openssh)
                "-i /run/${RuntimeDirectory}/id"
                "-o StrictHostKeyChecking=no"
                "-o ServerAliveInterval=3"
                "-p \"$PORT\""
                "-R0:${config.server.network.reverse-proxy.subnetPrefix}.2:443"
                "\"$GATEWAY\""
              ];

              User = "tunnel";
              Group = User;
              DynamicUser = true;
            };
          };

          system.stateVersion = cfg.systemStateVersion;
        };
      };
  };
}
