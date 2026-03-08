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
    default = {};
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
          { containerName, secrets, ... }:
          {
            name = "container@${containerName}";
            value.serviceConfig.LoadCredential = lib.pipe secrets [
              builtins.attrValues
              (map (secret: with secret; "${secretId name}:${path}"))
            ];
          }
        ))
        builtins.listToAttrs
      ];

      containers = lib.flip builtins.mapAttrs cfg.containers (
        containerName: container: {
          autoStart = lib.mkDefault true;
          privateUsers = lib.mkDefault "pick";
          config.system.stateVersion = lib.mkDefault config.system.stateVersion;

          bindMounts = lib.flip builtins.mapAttrs container.secrets (
            _:
            { name, ... }:
            {
              # Cannot use environment variable $CREDENTIALS_DIRECTORY :c
              hostPath = "/run/credentials/container@${containerName}.service/${secretId name}";
              mountPoint = "/run/credentials/${name}:owneridmap";
              isReadOnly = true;
            }
          );
        }
      );
    };
}
