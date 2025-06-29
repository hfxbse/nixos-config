{...}: {
  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults:root,%wheel timestamp_timeout=30
    '';
  };
}
