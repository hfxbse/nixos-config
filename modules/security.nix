{ ... }: {
  services.clamav = {
    updater.enable = true;
    daemon.enable = true;
  };

  networking.firewall.enable = true;
  networking.firewall.allowedUDPPorts = [
    24727   # AusweisApp2
  ];
}
