{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.ddns;
  inherit (lib) types;

  socketId = containerName: "${containerName}-${cfg.containers.${containerName}.interface}";

  containerNames = builtins.attrNames cfg.containers;

  defaultServiceHardening = {
    DynamicUser = true;
    NoNewPrivileges = true;
    PrivateTmp = true;
    PrivateDevices = true;
    PrivateMounts = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectSystem = "strict";
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
  };
in
{
  options.server.ddns = {
    useULA = lib.mkEnableOption {
      description = "Wether to allow the use of ULAs for debugging purposes. NEVER ENABLE IN PRODUCTION!";
    };

    defaultCredentialFile = lib.mkOption {
      description = "Path to the file containing the default credential for updating DNS records.";
      type = types.path;
    };

    containers = lib.mkOption {
      description = "Which container hosts the virtual hosts to update.";
      default = { };
      type = types.attrsOf (
        types.submodule (
          { ... }:
          {
            options = {
              interface = lib.mkOption {
                description = "Which container internet interface to query.";
                type = types.str;
              };

              domains = lib.mkOption {
                description = "Domains to update";
                type = types.listOf types.str;
              };

              credentialsFile = lib.mkOption {
                description = "Path to the file containing the credential for updating DNS records.";
                type = types.path;
                default = cfg.defaultCredentialFile;
              };
            };
          }
        )
      );
    };
  };

  config = {
    virtualisation.vmVariant.server.ddns.useULA = true;

    assertions =
      let
        nonExistingContainers = builtins.filter (
          name: !(builtins.hasAttr name config.containers)
        ) containerNames;
      in
      [
        {
          assertion = builtins.length nonExistingContainers == 0;
          message = "Containers used for DDNS updates do not exits: [${lib.concatStringsSep " " nonExistingContainers}]";
        }
      ];

    systemd =
      let
        transformContainerNames =
          service: f:
          lib.pipe containerNames [
            (map (containerName: {
              name = "${service}@${if service == "ddns" then socketId containerName else containerName}";
              value = f containerName;
            }))
            builtins.listToAttrs
          ];
      in
      {
        sockets = transformContainerNames "ddns" (containerName: {
          partOf = [ "container@${containerName}.service" ];
          socketConfig = {
            ListenFIFO = "/run/ddns/${socketId containerName}";
            RemoveOnStop = true;
          };
        });

        services =
          transformContainerNames "ddns" (containerName: rec {
            requires = [ "ddns@${socketId containerName}.socket" ];
            after = requires;
            serviceConfig = {
              Type = "oneshot";
              StandardInput = "socket";
              StandardOutput = "journal";
              StandardError = "journal";
              ExecStart = lib.getExe' pkgs.coreutils "cat";
              # Hardening
              DynamicUser = true;
            };
          })
          // transformContainerNames "container" (containerName: rec {
            requires = [ "ddns@${socketId containerName}.socket" ];
            after = requires;
          });
      };

    containers = lib.flip builtins.mapAttrs cfg.containers (
      containerName:
      { interface, ... }:
      {
        bindMounts.ddns-socket = {
          hostPath = "/run/ddns/${socketId containerName}";
          mountPoint = "/run/ddns/${interface}:owneridmap";
          isReadOnly = false;
        };

        config.systemd.services."ddns@${interface}" = {
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = defaultServiceHardening // rec {
            Restart = "always";
            RestartSec = "2s";
            AmbientCapabilities = [ ];
            # Hardening
            CapabilityBoundingSet = AmbientCapabilities;
            RestrictAddressFamilies = [
              "AF_NETLINK"
              "AF_UNIX"
            ];
          };

          script =
            let
              ip = lib.getExe' pkgs.iproute2 "ip";
              awk = lib.getExe pkgs.gawk;
              filter = lib.optionalString (!cfg.useULA) "| grep -v '^fd'";
            in
            /* bash */ ''
              function get_gua {
                GUA=$(
                  ${ip} -6 addr ls scope global dev '${interface}' \
                  | grep mngtmpaddr \
                  | ${awk} '/inet6/{print $2}' ${filter} #
                )

                [[ -n "$GUA" ]] && echo "$GUA" > '/run/ddns/${interface}'
              }

              get_gua;
              ${ip} -6 monitor address dev '${interface}' | while read -r _; do
                # Debounce
                sleep 2
                while read -r -t 0 _; do :; done

                get_gua
              done
            '';
        };
      }
    );
  };
}
