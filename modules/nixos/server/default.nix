{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server;
in
{
  imports = [
    ./dns.nix
    ./immich.nix
    ./monitoring.nix
    ./networking.nix
    ./oidc.nix
    ./reverse-proxy.nix
    ./tunnel.nix
  ];

  options.server = {
    enable = lib.mkEnableOption "server container support with systemd-nspawn";

    stateDirectories = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.listOf lib.types.path);
    };

    permissionMappings = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          let
            cfg = config;
          in
          {
            options = {
              server = lib.mkOption {
                type = lib.types.str;
                description = "Name of the server to which this fix gets attached to";
              };

              user = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = config._module.args.name;
                };

                nameOnServer = lib.mkOption {
                  type = lib.types.str;
                  default = cfg.user.name;
                };

                uid = lib.mkOption { type = lib.types.ints.positive; };
              };

              group = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = config.user.name;
                };

                nameOnServer = lib.mkOption {
                  type = lib.types.str;
                  default = cfg.group.name;
                };

                gid = lib.mkOption { type = lib.types.ints.positive; };
              };

              paths = lib.mkOption {
                type = lib.types.listOf lib.types.path;
              };

              chmod = {
                file = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 640;
                };

                dir = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 750;
                };
              };
            };
          }
        )
      );
    };
  };

  config =
    let
      mapAttributeNames =
        mappings:
        { context, nameAttr }:
        builtins.listToAttrs (
          builtins.map (
            mappingName:
            let
              mapping = mappings.${mappingName};
            in
            {
              name = mapping.${context}.${nameAttr};
              value = mapping;
            }
          ) (builtins.attrNames mappings)
        );

      createUserMapping = mappings: nameAttr: {
        groups =
          builtins.mapAttrs
            (mappingName: mapping: {
              name = mapping.group.${nameAttr};
              gid = mapping.group.gid;
            })
            (
              mapAttributeNames mappings {
                inherit nameAttr;
                context = "group";
              }
            );

        users =
          builtins.mapAttrs
            (mappingName: mapping: {
              name = mapping.user.${nameAttr};
              uid = mapping.user.uid;
              group = mapping.user.${nameAttr};
              extraGroups = lib.mkIf (mapping.user.${nameAttr} != mapping.group.${nameAttr}) [
                mapping.group.${nameAttr}
              ];
            })
            (
              mapAttributeNames mappings {
                inherit nameAttr;
                context = "group";
              }
            );
      };
    in
    lib.mkIf cfg.enable {
      users = createUserMapping cfg.permissionMappings "name";

      containers =
        lib.genAttrs (builtins.map (mapping: mapping.server) (builtins.attrValues cfg.permissionMappings))
          (server: {
            config.users = createUserMapping (lib.filterAttrs (
              mappingName: mapping: mapping.server == server
            ) cfg.permissionMappings) "nameOnServer";
          });

      systemd.services =
        let
          containerServices = builtins.map (name: "container@${name}") (
            builtins.attrNames cfg.stateDirectories
          );

          permissionCorrectionServices = builtins.map (name: "mount-permissions@${name}") (
            builtins.filter (name: builtins.length cfg.permissionMappings.${name}.paths > 0) (
              builtins.attrNames cfg.permissionMappings
            )
          );
        in
        lib.genAttrs containerServices (service: {
          serviceConfig = {
            StateDirectory =
              let
                directories = cfg.stateDirectories.${lib.removePrefix "container@" service};
              in
              builtins.map (directory: lib.removePrefix "/var/lib/" directory) directories;
          };
        })
        # Directory permission reset after every container restart
        # The internal services is NOT restarted when the container is restarted
        # The container does not "boot", meaning the usual mulit-user.target trigger
        # does not work.
        # Therefore, this workaround running on the host machine.
        // lib.genAttrs permissionCorrectionServices (
          service:
          let
            mapping = cfg.permissionMappings.${lib.removePrefix "mount-permissions@" service};
            trigger = [ "container@${mapping.server}.service" ];
          in
          {
            description = "Fixes the file permissions for the data stored by ${mapping.server}";
            wantedBy = trigger;
            partOf = trigger;
            after = trigger;
            serviceConfig = {
              Type = "simple";
              Restart = "on-failure";
              RestartSec = 30;
              NotifyAccess = "all";

              ExecStart =
                let
                  nixos-container = lib.getExe pkgs.nixos-container;
                  systemd-notify = "${pkgs.systemdMinimal}/bin/systemd-notify";
                  paths = lib.concatStringsSep " " mapping.paths;

                  fileMod = builtins.toString mapping.chmod.file;
                  dirMod = builtins.toString mapping.chmod.dir;
                in
                lib.getExe (
                  pkgs.writeShellScriptBin service ''
                    set -euo pipefail;

                    function mountChown {
                      ${nixos-container} run ${mapping.server} -- \
                          chown \
                              ${mapping.user.nameOnServer}:${mapping.group.nameOnServer} \
                              $@ ${paths};
                    }

                    function mountChmod {
                      type="$1";
                      shift;
                      mod="$1";
                      shift;

                      ${nixos-container} run ${mapping.server} -- \
                          find $@ ${paths} -type "$type" -exec chmod "$mod" {} +;
                    }

                    # Fallback to ignore links if a read only file is encountered
                    mountChown -L -R || mountChown -R;
                    mountChmod f ${fileMod} -L || mountChmod f ${fileMod};
                    mountChmod d ${dirMod} -L || mountChmod d ${dirMod};

                    ${systemd-notify} --ready;
                  ''
                );
            };
          }
        );
    };
}
