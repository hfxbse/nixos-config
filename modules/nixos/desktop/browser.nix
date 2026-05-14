{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.browser;
in
{
  options.desktop.browser.enable = lib.mkEnableOption "webbrowsing" // {
    default = config.desktop.enable;
  };

  config.programs.firefox = lib.mkIf cfg.enable {
    enable = true;

    policies = {
      AppAutoUpdate = false;
      Cookies.Behavior = "reject-tracker";
      DisableFirefoxAccounts = true;
      DisableAppUpdate = true;
      DisablePocket = true;
      DisableSetDesktopBackground = true;
      DisableTelemetry = false;
      DisplayBookmarksToolbar = "new-tab";
      DontCheckDefaultBrowser = true;

      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
      };

      EncryptedMediaExtensions = {
        Enabled = true;
        Locked = true;
      };

      PasswordManagerEnabled = false;

      SearchEngines = {
        Default = "DuckDuckGo";
        PreventInstalls = true;
        Remove = [
          "Google"
          "Bing"
          "Ecosia"
          "Wikipedia (en)"
        ];
      };

      ExtensionSettings = {
        "*".installation_mode = "blocked"; # blocks all addons except the ones specified below

        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
          default_area = "menupanel";
        };

        "support@netflux.me" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4382056/netflux-latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
          default_area = "menupanel";
        };

        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4541835/sponsorblock-latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
          default_area = "menupanel";
        };

        "zotero@chnm.gmu.edu" = {
          install_url = "https://www.zotero.org/download/connector/dl?browser=firefox";
          installation_mode = "normal_installed";
          private_browsing = true;
          default_area = "navbar";
        };

        "redirect-nix-wiki@undesided.me" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4373121/redirectnixwiki-latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
          default_area = "menupanel";
        };

        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4796063/bitwarden_password_manager-latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
          default_area = "navbar";
        };

        "1094918@gmail.com".installation_mode = "allowed";
      };

      FirefoxHome = {
        Search = true;
        TopSites = true;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        Stories = false;
        SponseredPocket = false;
        SponseredStories = false;
        Snippet = false;
        Locked = false;
      };

      FirefoxSuggest.SponsoredSuggestions = false;
      HardwareAcceleration = true;
      MicrosoftEntraSSO = false;

      PopupBlocking = {
        Allow = [
          "https://dhl.de"
          "https://office.com"
        ];
        Default = false;
        Locked = false;
      };

      PromptForDownloadLocation = true;
      RequestedLocales = [
        "en-US"
        "en"
        "de-DE"
        "de"
      ];

      ShowHomeButton = false;
      SkipTermsOfUse = true;
      WindowsSSO = false;
    };
  };
}
