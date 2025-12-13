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
  ];

  options.server = {
    enable = lib.mkEnableOption "server container support with systemd-nspawn";

    stateDirectories = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.listOf lib.types.path);
    };

    permissionCorrections = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule (
          { ... }:
          {
            options = {
              server = lib.mkOption {
                type = lib.types.str;
                description = "Name of the server to which this fix gets attached to";
              };
              user = lib.mkOption {
                type = lib.types.str;
              };

              group = lib.mkOption {
                type = lib.types.str;
              };

              path = lib.mkOption {
                type = lib.types.path;
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.services =
      let
        containerServices = builtins.map (name: "container@${name}") (
          builtins.attrNames cfg.stateDirectories
        );
        permissionCorrectionServices = builtins.map (name: "mount-permissions@${name}") (
          builtins.attrNames cfg.permissionCorrections
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
          correction = cfg.permissionCorrections.${lib.removePrefix "mount-permissions@" service};
          trigger = [ "container@${correction.server}.service" ];
        in
        {
          description = "Fixes the file permissions for the data stored by ${correction.server}";
          wantedBy = trigger;
          partOf = trigger;
          after = trigger;
          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              let
                nixos-container = lib.getExe pkgs.nixos-container;
              in
              lib.getExe (
                pkgs.writeShellScriptBin service ''
                  ${nixos-container} run ${correction.server} -- \
                  chown ${correction.user}:${correction.group} -R -L ${correction.path};
                ''
              );
          };
        }
      );
  };
}
