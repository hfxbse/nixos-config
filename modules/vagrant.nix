{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.development.vagrant;
  libvirtd = cfg.hypervisor == "libvirtd";
in
{
  options.development.vagrant = {
    enable = lib.mkEnableOption "Vagrant support";

    user = lib.mkOption {
      description = "Username of the Vagrant user.";
      type = lib.types.str;
    };

    hypervisor = lib.mkOption {
      description = "Which hypervisors to enable";
      type = lib.types.enum [ "libvirtd" ];
      default = "libvirtd";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nfs.server.enable = lib.mkDefault true;
    users.users.${cfg.user}.packages = [ pkgs.vagrant ];

    # libvirtd setup.
    virtualisation.libvirtd.enable = lib.mkDefault libvirtd;
    users.groups.libvirtd.members = lib.optional libvirtd cfg.user;

    networking.firewall.interfaces."virbr1" = lib.mkIf libvirtd {
      allowedTCPPorts = [ 2049 ];
      allowedUDPPorts = [ 2049 ];
    };
  };
}
