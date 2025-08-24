{ config, lib, ... }:
let
  cfg = config.desktop.browser;
in
{
  options.desktop.browser.enable = lib.mkEnableOption "webbrowsing" // {
    default = true;
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

        "jid1-ZAdIEUB7XOzOJw@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4540706/duckduckgo_for_firefox-latest.xpi";
          installation_mode = "force_installed";
          private_browsing = true;
          default_area = "navbar";
        };

        "zotero@chnm.gmu.edu" = {
          install_url = "https://www.zotero.org/download/connector/dl?browser=firefox";
          installation_mode = "normal_installed";
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
