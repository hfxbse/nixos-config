final: prev: {
  bluez = prev.bluez.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [
      (final.fetchpatch2 {
        # See https://github.com/bluez/bluez/issues/2321#issuecomment-6399514961
        url = "https://git.kernel.org/pub/scm/bluetooth/bluez.git/patch/?id=b7d71e5067856b0daf2f1f73b3fc95483236610e";
        hash = "sha256-0+YmgVASf+aExTZ/AAvJOEUXNx03ks6n9qRiHX3CCXE=";
      })
    ];
  });
}
