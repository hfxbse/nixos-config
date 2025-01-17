{
  asar,
  electron_24,
  fetchzip,
  lib,
  makeDesktopItem,
  makeWrapper,
  stdenv,
}:
let
  version = "6.5.46";
  desktopItem = makeDesktopItem {
    name = "easyeda";
    desktopName = "EasyEDA";
    comment = "A simple and powerful electronic circuit design tool";
    icon = "easyeda";
    exec = "easyeda %f";
    categories = [ "Development" "Electronics" ];
  };

  electron = electron_24;
in
stdenv.mkDerivation {
  pname = "easyeda";
  inherit version;

  src = fetchzip {
    url = "https://image.easyeda.com/files/easyeda-linux-x64-${version}.zip";
    hash = "sha256-0aMh8dD3z4A4IA1hlAwz9VeERlRWHe9HV54u7+OyKFM=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    asar
    makeWrapper
  ];

  patchPhase = ''
    app=easyeda-linux-x64;

    asar extract $app/resources/app.asar patched-asar;

    sed -i "s#process\.resourcesPath#'$out/share/easyeda'#g" patched-asar/index.bundle.js;

    asar pack patched-asar $app/resources/app.asar;
  '';

  installPhase = ''
    app=easyeda-linux-x64;

    mkdir -p $out/bin $out/share/easyeda;

    cp -r $app/resources/* $out/share/easyeda;

    makeWrapper ${electron}/bin/electron $out/bin/easyeda \
      --add-flags $out/share/easyeda/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform=wayland}}";

    install -m 444 -D ${desktopItem}/share/applications/* -t $out/share/applications/;

    for size in 16 32 48 64 128 256; do
      install -m 444 -D $app/icon/''${size}x''${size}/easyeda.png -t $out/share/icons/hicolor/''${size}x''${size}/apps/;
    done;
  '';
}
