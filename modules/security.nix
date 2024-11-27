{ ... }: {
  services.clamav = {
    updater.enable = true;
    daemon.enable = true;
  };

  networking.firewall = {
    enable = true;
    checkReversePath = "loose";

    allowedTCPPorts = [
      53      # DNS
    ];

    allowedUDPPorts = [
      53      # DNS
      67      # DHCP

      24727   # AusweisApp2
    ];
  };
}
