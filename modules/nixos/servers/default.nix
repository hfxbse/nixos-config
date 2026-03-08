{ config, lib, ... }:
let
  types = lib.types;
  cfg = config.server;
in
{
  imports = [
    ./dns.nix
    ./dummy.nix
    ./dummy-http.nix
    ./ingress.nix
    ./oidc.nix
    ./reverse-proxy.nix
  ];

  options.server.containers = lib.mkOption {
    default = { };
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options.containerName = lib.mkOption {
            # Required as getting them dynamically results in an infinite recursion
            description = "Name of the server containers to which apply the default config to.";
            type = types.str;
            default = name;
          };

          options.dataDirs = lib.mkOption {
            description = "Directories to mount into the containers to keep its state.";
            default = { };
            type = types.attrsOf (
              types.submodule (
                { ... }:
                {
                  options.host.path = lib.mkOption {
                    description = "Path to the data directory on the host.";
                    type = lib.types.addCheck lib.types.path (p: lib.hasPrefix "/var/lib/" (toString p));
                  };

                  options.container.path = lib.mkOption {
                    description = "Path to the data directory inside the container.";
                    type = types.path;
                  };

                  options.container.uid = lib.mkOption {
                    description = "ID of the user inside the container owning the directory.";
                    type = types.ints.unsigned;
                    default = 0;
                  };

                  options.container.gid = lib.mkOption {
                    description = "ID of the group inside the container owning the directory.";
                    type = types.ints.unsigned;
                    default = 0;
                  };
                }
              )
            );
          };

          options.secrets = lib.mkOption {
            description = "The secret to be loaded into the container.";
            default = { };
            type = types.attrsOf (
              types.submodule (
                { name, ... }:
                {
                  options.path = lib.mkOption {
                    description = "Paths to the secrets on the host system.";
                    type = types.path;
                  };

                  options.name = lib.mkOption {
                    description = "Name of the loaded secret inside of the container.";
                    type = types.str;
                    default = name;
                  };
                }
              )
            );
          };
        }
      )
    );
  };

  config =
    let
      secretId = name: builtins.hashString "sha1" name;
    in
    {
      systemd.services = lib.pipe cfg.containers [
        builtins.attrValues
        (map (
          {
            containerName,
            secrets,
            dataDirs,
            ...
          }:
          {
            name = "container@${containerName}";
            value = {
              script = lib.pipe dataDirs [
                builtins.attrValues
                (map (
                  dataDir: with dataDir.container; ''
                    mkdir -p "$root${path}"
                    chown ${toString uid}:${toString gid} "$root${path}"
                  ''
                ))
                (builtins.concatStringsSep "\n")
                lib.mkBefore
              ];

              serviceConfig = {
                LoadCredential = lib.pipe secrets [
                  builtins.attrValues
                  (map (secret: with secret; "${secretId name}:${path}"))
                ];

                StateDirectoryMode = "0750"; # rwx r-x ---
                StateDirectory = lib.pipe dataDirs [
                  builtins.attrValues
                  (map ({ host, ... }: lib.removePrefix "/var/lib/" host.path))
                ];

              };
            };
          }
        ))
        builtins.listToAttrs
      ];

      containers = lib.flip builtins.mapAttrs cfg.containers (
        containerName: container: {
          autoStart = lib.mkDefault true;
          privateUsers = lib.mkDefault "pick";
          config.system.stateVersion = lib.mkDefault config.system.stateVersion;

          bindMounts =
            (lib.flip builtins.mapAttrs container.secrets (
              _:
              { name, ... }:
              {
                # Cannot use environment variable $CREDENTIALS_DIRECTORY :c
                hostPath = "/run/credentials/container@${containerName}.service/${secretId name}";
                mountPoint = "/run/credentials/${name}:owneridmap";
                isReadOnly = true;
              }
            ))
            // lib.flip builtins.mapAttrs container.dataDirs (
              _:
              { host, container, ... }:
              {
                mountPoint = "${container.path}:owneridmap";
                hostPath = host.path;
                isReadOnly = false;
              }
            );
        }
      );
    };
}
