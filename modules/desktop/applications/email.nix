{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.applications.email;
  inherit (config.applications) language;
in
{
  options.applications.email = {
    enable = lib.mkEnableOption "Whether to install emailing tools.";

    backgroundSync =
      lib.mkEnableOption "Whether to enable background synchronisation and notifications of emails."
      // {
        default = true;
      };

    sieve = lib.mkEnableOption "Whether to install a sieve rule editor." // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional cfg.sieve pkgs.sieve-editor-gui;

    programs.thunderbird = {
      enable = true;
      languagePacks = [ (if language == "en" then "en-US" else "de") ];
      settings = {
        "mailnews.default_sort_order" = 2;
        "mailnews.default_sort_type" = 18;
      };

      package = lib.mkIf cfg.backgroundSync (
        # Use two systemd services to run Thunderbird.
        # One for the GUI and one for the headless background sync.
        # The headless thunderbird instance needs to be stopped for the GUI to work.
        # See https://discourse.nixos.org/t/mozilla-thunderbird-birdtray-on-wayland/59811
        pkgs.thunderbird.overrideAttrs (prev: {
          nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
          postFixup = (prev.postFixup or "") + ''
            wrapProgram $out/bin/thunderbird \
              --run 'systemctl --user start thunderbird-gui'
          '';
        })
      );
    };

    systemd.user.services = lib.mkIf cfg.backgroundSync {
      thunderbird-monitor = {
        Install.WantedBy = [ "graphical-session.target" ];
        Unit = {
          Description = "Mozilla Thunderbird Monitoring service";
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.thunderbird}/bin/.thunderbird-wrapped__ --headless";
          Restart = "on-failure";
          RestartSec = "10sec";
        };
      };

      thunderbird-gui = {
        Unit = {
          Description = "Mozilla Thunderbird GUI service";
          PartOf = [ "graphical-session.target" ];
          Conflicts = [ "thunderbird-monitor.service" ];
          After = [ "thunderbird-monitor.service" ];
        };

        Service =
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
