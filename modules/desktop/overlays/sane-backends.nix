final: prev: {
  # Symlink to avoid rebuilding from source, `callPackage` to allow overriding
  sane-backends = prev.callPackage (
    inputs:
    prev.symlinkJoin {
      name = "sane-backends";
      paths = with prev; [ (sane-backends.override inputs) ];
      postBuild = ''
        CONFIG="/etc/sane.d/genesys.conf"
        rm "$out/$CONFIG"
        cp "${prev.sane-backends}/$CONFIG" "$out/$CONFIG"
        sed -i 's/#usb 0x04a9 0x2228/usb 0x04a9 0x2228/' "$out/$CONFIG"
        ls
      '';
    }
  ) { };

  # Break dependency chain on the sane backends to avoid long compilation times
  colord = prev.colord.override {
    sane-backends = prev.sane-backends;
  };

  libreoffice-unwrapped = prev.libreoffice-unwrapped.override {
    sane-backends = prev.sane-backends;
  };
}
