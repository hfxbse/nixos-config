{ ... }:
{
  networking.firewall.enable = true;

  services.fail2ban = {
    enable = true;
    bantime = "1d";
    bantime-increment.multipliers = "1 2 4 8 16 32 64";
    bantime-increment.rndtime = "5h";
    maxretry = 5;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      LogLevel = "VERBOSE";
      PasswordAuthentication = false;
    };
  };
}
