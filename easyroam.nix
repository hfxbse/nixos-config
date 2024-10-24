{
  binutils,
  gnutar,
  stdenv,
  fetchurl
}:
let
  version = "1.3.5";
in
stdenv.mkDerivation {
  pname = "easyroam";
  inherit version;

  src = fetchurl {
    url = "https://packages.easyroam.de/repos/easyroam-desktop/pool/main/e/easyroam-desktop/easyroam_connect_desktop-${version}+${version}-linux.deb";
    hash = "sha256-0Oh6rIIxyhVWhz/L5+P3zqIJqL9Ujz3rKKujiNwrZ40=";
    recursiveHash = true;

    nativeBuildInputs = [ binutils gnutar ];

    downloadToTemp = true;
    postFetch = ''
      mkdir -p $out $out/control $out/data;

      ar x $downloadedFile --output=$out;
      tar -xf $out/control.tar.xz -C $out/control;
      tar -xf $out/data.tar.xz -C $out/data;

      rm $out/*.tar.xz
    '';
  };
}
