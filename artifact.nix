{
  autoPatchelfHook,
  architecture,
  engineShortVersion,
  fetchzip,
  fontconfig,
  glib,
  hash,
  lib,
  libdrm,
  libgbm,
  libGL,
  libinput,
  libxkbcommon,
  patch,
  profile ? null,
  stdenv,
  version,
  wayland
}:
let
  engineArtifactBaseUrl = "https://github.com/sony/flutter-embedded-linux/releases/download/${engineShortVersion}";
  profileString = "${if profile == null then "" else "-${profile}"}";
in
stdenv.mkDerivation {
  pname = "elinux-engine-${architecture}${profileString}";
  inherit version;

  src = fetchzip {
    inherit hash;
    url = "https://github.com/sony/flutter-embedded-linux/releases/download/${engineShortVersion}/elinux-${architecture}${profileString}.zip";
    stripRoot = false;
  };

  autoPatchelfIgnoreMissingDeps = [ "libflutter_elinux*" ];
  nativeBuildInputs = lib.optionals patch [
    autoPatchelfHook
    fontconfig
    glib
    libdrm
    libgbm
    libGL
    libinput
    libxkbcommon
    wayland
  ];

  installPhase = ''
    TARGET="$out/elinux-${architecture}${profileString}";
    mkdir -p $TARGET;
    mv * $TARGET;
  '';
}
