{
  advobfuscator,
  boost,
  c-ares,
  callPackage,
  cmake,
  cmakerc,
  cpp-base64,
  cpp-netlib,
  fetchFromGitHub,
  gtest,
  miniaudio,
  openssl,
  qtbase,
  qtimageformats,
  qtsvg,
  qttools,
  qtwayland,
  rapidjson,
  skyr-url,
  spdlog,
  stdenv,
  wrapQtAppsHook,
  ...
}:
let
  version = "2.17.3";
  src = fetchFromGitHub {
    owner = "Windscribe";
    repo = "Desktop-App";
    tag = "v${version}";
    hash = "sha256-CC3fU/Dy4BNVqnTFuSOqYALHIz6XAivNqXqnm2tQYJg=";
  };

  curl = callPackage (import ./curl.nix) {
    windscribeSrc = src;
  };
in
stdenv.mkDerivation {
  inherit version src;
  pname = "windscribeDesktopApp";

  patches = [
    ./curl.patch
    ./install.patch
  ];

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    advobfuscator
    boost
    c-ares
    cmakerc
    cpp-netlib
    curl.dev
    gtest
    miniaudio
    openssl
    skyr-url
    spdlog
    qtbase
    qtimageformats
    qtsvg
    qttools
    qtwayland
    rapidjson
    wrapQtAppsHook
  ];

  cmakeFlags = [
    "-S ../client"
    "-DADVOBFUSCATOR_INCLUDE_DIRS=${advobfuscator}/include/advobfuscator"
    "-DCPP_BASE64_INCLUDE_DIRS=${cpp-base64}/include"
    "-DCMAKE_EXE_LINKER_FLAGS=-lcares"
  ];

  fixupPhase = ''
    mkdir $out/bin;
    mv $out/Windscribe $out/bin/Windscribe;
    ln -s $out/bin/Windscribe $out/bin/windscribe-desktop-app;
  '';
}
