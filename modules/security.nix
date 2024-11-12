{ ... }: {
  services.clamav = {
    updater.enable = true;
    daemon.enable = true;
  };

  networking.firewall = {
    enable = true;
    checkReversePath = "loose";

    allowedUDPPorts = [
      67      # DHCP

      24727   # AusweisApp2
    ];
  };
}
