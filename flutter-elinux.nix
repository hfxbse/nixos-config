{
  fetchFromGitHub,
  fetchurl,
  fetchzip,
  flutter327,
  lib,
  makeWrapper,
  stdenv
}:
let
  pname = "flutter-elinux";
  version = "3.27.1";

  flutter = flutter327;
  engineArtifactHash = "cb4b5fff73";
  engineArtifactBaseUrl = "https://github.com/sony/flutter-embedded-linux/releases/download/${engineArtifactHash}";
in
stdenv.mkDerivation {
  inherit pname;
  inherit version;

  srcs = [
    (fetchFromGitHub {
      name = pname;
      owner = "sony";
      repo = "flutter-elinux";
      tag = version;
      hash = "sha256-4gnrFvRu40Q9ejDwkcaunTTw77jpxP8NzSmszDjex+g=";
    })
    (fetchFromGitHub {
      name = "flutter";
      owner = "flutter";
      repo = "flutter";
      tag = version;
      hash = "sha256-WK6Ecaxs2MAlqOyKDPfXg1d4mqyAi7NZ/lFdMZwqkzQ=";
    })
    (fetchurl {
      url = "${engineArtifactBaseUrl}/elinux-arm64-debug.zip";
      hash = "sha256-C9KCA2iQ9CEAIRJN2fGf21Nu5oy+7ekt+eAiPfO6s1M=";
    })
    (fetchurl {
      url = "${engineArtifactBaseUrl}/elinux-arm64-profile.zip";
      hash = "sha256-tAtnmtd+7N1OifVArweuA4SEg1WHyPmfyEMTF+wT9ZY=";
    })
    (fetchurl {
      url = "${engineArtifactBaseUrl}/elinux-arm64-release.zip";
      hash = "sha256-qoqfQVPhnrDryYXa0fGwvcrm1u2wnTHWNIrTt8GknPo=";
    })
    (fetchurl {
      url = "${engineArtifactBaseUrl}/elinux-common.zip";
      hash = "sha256-ogR0W6cU8gzHni6dYqRA9+lS1xG14AnY8QDjAwSyP6g=";
    })
    (fetchurl {
      url = "${engineArtifactBaseUrl}/elinux-x64-debug.zip";
      hash = "sha256-TfGzsAiK9czbgGU1LSzSKOhonJAUl2CZo6MyOhus6VY=";
    })
    (fetchurl {
      url = "${engineArtifactBaseUrl}/elinux-x64-profile.zip";
      hash = "sha256-ycM4Ix2h8mRGjaddJMaIWRFqk6+NuKstHw4Gn7XVgYQ=";
    })
    (fetchurl {
      url = "${engineArtifactBaseUrl}/elinux-x64-release.zip";
      hash = "sha256-Je/jqnsnZ2xZoreEtH50DNPspCrdDh0322bp29ZZKZs=";
    })
  ] ++ (map ( {url, hash, name, ...}: fetchzip {
    inherit url;
    inherit hash;
    inherit name;
    stripRoot = false;
  } ) ( builtins.fromJSON ( builtins.readFile ./package-sources.json ) ).packages );

  sourceRoot = ".";
  unpackPhase = ''
    for src in $srcs; do
      # Get basename without the hash
      TARGET=$(cut -d "-" -f2- <<< $(basename "$src"));
      cp -r $src $TARGET;
    done;

    chmod -R 755 .
    mv flutter flutter-elinux/
    mkdir flutter-elinux/.dart_tool

    mkdir engine-artifacts;
    mv *.zip engine-artifacts;

    PACKAGE_TARGET=".pub-cache/hosted/pub.dev"
    mkdir -p "$PACKAGE_TARGET";
    mv * "$PACKAGE_TARGET";
    mv "$PACKAGE_TARGET/flutter-elinux" "$PACKAGE_TARGET/engine-artifacts" .
  '';

  buildInputs = [ flutter ];
  nativeBuildInputs = [
    flutter
    makeWrapper
  ];

  buildPhase = ''
    mkdir .config;
    cd flutter-elinux;

    export PUB_CACHE="../.pub-cache"
    export XDG_CONFIG_HOME=../.config;
    export ELINUX_ENGINE_BASE_LOCAL_DIRECTORY=../engine-artifacts;
    flutter config --no-cli-animations --no-analytics;
    flutter pub get --no-precompile --offline;
    mkdir -p bin/cache/;
    dart --disable-dart-dev \
         --no-enable-mirrors \
         --snapshot="bin/cache/flutter-elinux.snapshot" \
         --packages=".dart_tool/package_config.json" \
         "bin/flutter_elinux.dart";

    cd -;
  '';

  installPhase = ''
    mkdir -p $out/opt $out/bin;
    mv flutter-elinux $out/opt;
    mkdir -p $out/opt/flutter-elinux/flutter/bin/cache;

    makeWrapper ${flutter}/bin/dart $out/bin/flutter-elinux \
      --add-flags "--disable-dart-dev" \
      --add-flags "--packages=$out/opt/flutter-elinux/.dart_tool/package_config.json" \
      --add-flags "$out/opt/flutter-elinux/bin/cache/flutter-elinux.snapshot"
  '';
}
