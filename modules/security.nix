{ ... }: {
  services.clamav = {
    updater.enable = true;
    daemon.enable = true;
  };

  networking.firewall = {
    enable = true;
    checkReversePath = "loose";

    allowedUDPPorts = [
      24727   # AusweisApp2
    ];
  };
}
