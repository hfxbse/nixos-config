final: prev: {
  sane-backends = prev.sane-backends.overrideAttrs {
    # Enable potentially dangerous Canon 4400F support
    fixupPhase = ''
      sed -i 's/#usb 0x04a9 0x2228/usb 0x04a9 0x2228/' $out/etc/sane.d/genesys.conf
    '';
  };
}
