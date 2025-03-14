{
  fetchFromGitHub,
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
  engineArtifactShortHash = "cb4b5fff73";
  engineArtifactHash = "cb4b5fff73850b2e42bd4de7cb9a4310a78ac40d";
  engineArtifactBaseUrl = "https://github.com/sony/flutter-embedded-linux/releases/download/${engineArtifactShortHash}";
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
    (fetchzip {
      url = "${engineArtifactBaseUrl}/elinux-arm64-debug.zip";
      hash = "sha256-M0IcOoeVtVb02Lx6YVhV4eLhHgc1XEZs1mGNrUr77Ew=";
      stripRoot = false;
      name = "elinux-arm64-debug";
    })
    (fetchzip {
      url = "${engineArtifactBaseUrl}/elinux-arm64-profile.zip";
      hash = "sha256-awxmWQ83Sb5b8/djfcJUhMXaLCWdU04Vp/nuPr0jwJk=";
      stripRoot = false;
      name = "elinux-arm64-profile";
    })
    (fetchzip {
      url = "${engineArtifactBaseUrl}/elinux-arm64-release.zip";
      hash = "sha256-yvzV0Bf4QxFLfZvTaONn9q4GQmRRW8GLNtwEjqGeMWg=";
      stripRoot = false;
      name = "elinux-arm64-release";
    })
    (fetchzip {
      url = "${engineArtifactBaseUrl}/elinux-common.zip";
      hash = "sha256-KmRa8bdEXoK3PIjYxpEe5IyIXcmjRF55FFjVpXad92I=";
      stripRoot = false;
      name = "elinux-common";
    })
    (fetchzip {
      url = "${engineArtifactBaseUrl}/elinux-x64-debug.zip";
      hash = "sha256-Eqe97gZ3LAwKaBjltC7vFduYKDuhu50BjNyj/xuGoO0=";
      stripRoot = false;
      name = "elinux-x64-debug";
    })
    (fetchzip {
      url = "${engineArtifactBaseUrl}/elinux-x64-profile.zip";
      hash = "sha256-wlRvyucuFACR903/NzkqS9DFGng5LlK5sf3PCpKCQYE=";
      stripRoot = false;
      name = "elinux-x64-profile";
    })
    (fetchzip {
      url = "${engineArtifactBaseUrl}/elinux-x64-release.zip";
      hash = "sha256-oPtu0/XlrScPoppGzXuitDREEm8ldeCcCEFm9JcRXVM=";
      stripRoot = false;
      name = "elinux-x64-release";
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
    ln -s ${flutter} flutter-elinux/flutter;
    mkdir flutter-elinux/.dart_tool

    mkdir engine-artifacts;
    mv elinux* engine-artifacts;

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
    flutter config --no-cli-animations --no-analytics;
    flutter pub get --no-precompile --offline;
    mkdir -p bin/cache/;
    dart --disable-dart-dev \
         --no-enable-mirrors \
         --define=NIX_FLUTTER_HOST_PLATFORM=${stdenv.hostPlatform.system} \
         --snapshot="bin/cache/flutter-elinux.snapshot" \
         --packages=".dart_tool/package_config.json" \
         "bin/flutter_elinux.dart";

    cd -;
  '';

  installPhase = ''
    target="$out/opt/flutter-elinux"

    mkdir -p $out/opt $out/bin;
    mv flutter-elinux $out/opt;

    rm $target/flutter;
    mkdir $target/flutter;
    ln -s ${flutter}/* $target/flutter/;

    rm $target/flutter/bin;
    mkdir $target/flutter/bin;
    ln -s ${flutter}/bin/* $target/flutter/bin/;

    rm $target/flutter/bin/cache;
    mkdir $target/flutter/bin/cache;
    ln -s ${flutter}/bin/cache/* $target/flutter/bin/cache/;

    rm $target/flutter/bin/cache/artifacts;
    mkdir $target/flutter/bin/cache/artifacts;
    ln -s ${flutter}/bin/cache/artifacts/* \
          $target/flutter/bin/cache/artifacts;

    rm $target/flutter/bin/cache/artifacts/engine;
    mkdir $target/flutter/bin/cache/artifacts/engine;
    ln -s ${flutter}/bin/cache/artifacts/engine/* \
          $target/flutter/bin/cache/artifacts/engine;

    mv engine-artifacts/* $target/flutter/bin/cache/artifacts/engine/;

    echo "${engineArtifactHash}" > "$target/flutter/bin/cache/elinux-sdk.stamp";

    makeWrapper ${flutter}/bin/dart $out/bin/flutter-elinux \
      --add-flags "--disable-dart-dev" \
      --add-flags "--define=NIX_FLUTTER_HOST_PLATFORM=${stdenv.hostPlatform.system}" \
      --add-flags "--packages=$out/opt/flutter-elinux/.dart_tool/package_config.json" \
      --add-flags "$out/opt/flutter-elinux/bin/cache/flutter-elinux.snapshot"
  '';
}
