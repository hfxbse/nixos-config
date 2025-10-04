{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.email;
in
{
  options.desktop.email = {
    enable = lib.mkEnableOption "emailing tools" // {
      default = config.desktop.enable;
    };

    backgroundSync = lib.mkEnableOption "background syncronization and notifications of emails" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.thunderbird = {
      enable = true;
      preferences = {
        "mailnews.default_sort_order" = 2;
        "mailnews.default_sort_type" = 18;
      };
    };

    users.users.${config.user.name}.packages = with pkgs; [ sieve-editor-gui ];

    # Use two systemd services to run Thunderbird.
    # One for the GUI and one for the headless background sync.
    # The headless thunderbird instance needs to be stopped for the GUI to work.
    # See https://discourse.nixos.org/t/mozilla-thunderbird-birdtray-on-wayland/59811
    nixpkgs.overlays = lib.mkIf cfg.backgroundSync [
      (final: prev: {
        thunderbird = prev.symlinkJoin {
          name = "thunderbird-wrapper";
          paths = with prev; [ thunderbird ];
          nativeBuildInputs = with prev; [ makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/thunderbird \
              --run 'systemctl --user start thunderbird-gui'
          '';
        };
      })
    ];

    systemd.user.services = lib.mkIf cfg.backgroundSync {
      thunderbird-monitor = {
        enable = true;
        description = "Mozilla Thunderbird Monitoring service";

        partOf = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];

        serviceConfig = {
          ExecStart = "${pkgs.thunderbird}/bin/.thunderbird-wrapped__ --headless";
          Restart = "on-failure";
          RestartSec = "10sec";
        };
      };
      thunderbird-gui = {
        enable = true;
        description = "Mozilla Thunderbird GUI service";
        partOf = [ "graphical-session.target" ];
        conflicts = [ "thunderbird-monitor.service" ];
        after = [ "thunderbird-monitor.service" ];

        serviceConfig =
          let
            # Best-effort guess when Thunderbird is "ready" (i.e. started up
            # enough to reject subsequent instance starts), as subsequent
            # thunderbird invocations shouldn't spawn a new-instance but
            # can change the active instance (i.e. thunderbird -mail)
            thunderbird-gui = pkgs.writeShellScriptBin "thunderbird-gui" ''
              ${pkgs.thunderbird}/bin/.thunderbird-wrapped__ &
              pid="$!"
              sleep 3
              systemd-notify --ready
              wait "$pid"
            '';
          in
          {
            Type = "notify";
            NotifyAccess = "all";
            ExecStart = "${thunderbird-gui}/bin/thunderbird-gui";
            ExecStopPost = "systemctl --user --no-block start thunderbird-monitor";
          };
      };
    };
  };
}
