{
  alsa-lib,
  autoPatchelfHook,
  dbus,
  fetchzip,
  gtk3,
  libgcc,
  libxkbcommon,
  libXext,
  makeFontsConf,
  mesa,
  nss,
  pango,
  stdenv
}:
let
  version = "6.5.46";
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
    autoPatchelfHook
  ];

  buildInputs = [
    alsa-lib
    dbus
    gtk3
    libgcc
    libxkbcommon
    libXext
    mesa
    nss
    pango
  ];

  installPhase = ''
    mkdir -p $out/opt $out/bin $out/share/applications;

    cp -r $src/easyeda-linux-x64 $out/opt/easyeda;
    cp $src/easyeda-linux-x64/EASYEDA.dkt $out/share/applications/easyeda.desktop;
    ln -s $out/opt/easyeda/easyeda $out/bin/easyeda;

    chmod -R 755 $out/opt/easyeda;
    chmod 755 $out/bin/easyeda;
  '';
}
