{
  atk,
  cairo,
  clang,
  cmake,
  fetchFromGitHub,
  fetchzip,
  flutter327,
  fontconfig,
  gdk-pixbuf,
  glib,
  gnumake,
  gtk3,
  harfbuzz,
  lib,
  libepoxy,
  libdeflate,
  libGL,
  libX11,
  makeWrapper,
  ninja,
  pango,
  pkg-config,
  stdenv,
  xorgproto,
  zlib
}:
let
  pname = "flutter-elinux";
  version = "3.27.1";

  flutter = flutter327;
  engineArtifactShortHash = "cb4b5fff73";
  engineArtifactHash = "cb4b5fff73850b2e42bd4de7cb9a4310a78ac40d";
  engineArtifactBaseUrl = "https://github.com/sony/flutter-embedded-linux/releases/download/${engineArtifactShortHash}";

  buildTools = [
    clang
    cmake
    flutter
    gnumake
    ninja
    pkg-config
  ];

  appRuntimeDeps = [
    atk
    cairo
    fontconfig
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libepoxy
    libGL
    libX11
    libdeflate
    pango
  ];

  # Development packages required for compilation.
  appBuildDeps =
    let
      # https://discourse.nixos.org/t/handling-transitive-c-dependencies/5942/3
      deps =
        pkg:
        builtins.filter lib.isDerivation ((pkg.buildInputs or [ ]) ++ (pkg.propagatedBuildInputs or [ ]));
      collect = pkg: lib.unique ([ pkg ] ++ deps pkg ++ builtins.concatMap collect (deps pkg));
    in
    builtins.concatMap collect appRuntimeDeps;

  appStaticBuildDeps = [
    libX11
    xorgproto
    zlib
  ];

  pkgConfigPackages = map (lib.getOutput "dev") appBuildDeps;
  includeFlags = map (pkg: "-isystem ${lib.getOutput "dev" pkg}/include") appStaticBuildDeps;
  linkerFlags = map (pkg: "-rpath,${lib.getOutput "lib" pkg}/lib") appRuntimeDeps;
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

  patches = [
    ./patches/disable-precaching.patch
    ./patches/template-copying.patch
  ];

  sourceRoot = ".";
  unpackPhase = ''
    for src in $srcs; do
      # Get basename without the hash
      TARGET=$(cut -d "-" -f2- <<< $(basename "$src"));
      cp -r $src $TARGET;
    done;

    cp -r ${flutter}/packages/flutter_tools .;

    chmod -R 755 .
    ln -s ${flutter} flutter-elinux/flutter;
    mkdir flutter-elinux/.dart_tool

    mkdir engine-artifacts;
    mv elinux* engine-artifacts;

    PACKAGE_TARGET=".pub-cache/hosted/pub.dev"
    mkdir -p "$PACKAGE_TARGET";
    mv * "$PACKAGE_TARGET";
    mv "$PACKAGE_TARGET/flutter-elinux" \
       "$PACKAGE_TARGET/engine-artifacts" \
       "$PACKAGE_TARGET/flutter_tools" \
       .;
  '';

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

    ls;
    cd flutter_tools/;

    flutter pub get --offline;

    cd -;
  '';

  installPhase = ''
    for path in ${
      builtins.concatStringsSep " " (
        builtins.foldl' (
          paths: pkg:
          paths
          ++ (map (directory: "'${pkg}/${directory}/pkgconfig'") [
            "lib"
            "share"
          ])
        ) [ ] pkgConfigPackages
      )
    }; do
      addToSearchPath FLUTTER_PKG_CONFIG_PATH "$path"
    done

    target="$out/opt/flutter-elinux"

    unlinkFlutter () {
      local path="$1";

      local task="$target/flutter/$path";

      if [ "$path" == "" ] || [ "$path" == "." ]; then
        rm "$target/flutter";
      else
        rm "$task";
      fi

      mkdir "$task";
      ln -s ${flutter}/$path/* "$task";
    }

    mkdir -p $out/opt $out/bin;
    mv flutter-elinux $out/opt;

    unlinkFlutter;
    unlinkFlutter bin;
    unlinkFlutter bin/cache;
    unlinkFlutter bin/cache/artifacts;
    unlinkFlutter bin/cache/artifacts/engine;
    mv engine-artifacts/* $target/flutter/bin/cache/artifacts/engine/;
    echo "${engineArtifactHash}" > "$target/flutter/bin/cache/elinux-sdk.stamp";

    unlinkFlutter packages;
    unlinkFlutter packages/flutter_tools;
    unlinkFlutter packages/flutter_tools/templates;
    unlinkFlutter packages/flutter_tools/templates/app;
    mv $target/templates/app $target/flutter/packages/flutter_tools/templates/app/elinux.tmpl;

    unlinkFlutter packages/flutter_tools/templates/plugin;
    mv $target/templates/plugin $target/flutter/packages/flutter_tools/templates/plugin/elinux.tmpl;

    mkdir $target/flutter/packages/flutter_tools/.dart_tool;
    mv flutter_tools/.dart_tool/package_config.json $target/flutter/packages/flutter_tools/.dart_tool;

    chmod 555 -R $out/opt/;

    makeWrapper ${flutter}/bin/dart $out/bin/flutter-elinux \
      --set-default ANDROID_EMULATOR_USE_SYSTEM_LIBS 1 \
      --suffix PKG_CONFIG_PATH : "$FLUTTER_PKG_CONFIG_PATH" \
      --suffix LIBRARY_PATH : '${lib.makeLibraryPath appStaticBuildDeps}' \
      --prefix CXXFLAGS "''\t" '${builtins.concatStringsSep " " includeFlags}' \
      --prefix CFLAGS "''\t" '${builtins.concatStringsSep " " includeFlags}' \
      --prefix LDFLAGS "''\t" '${builtins.concatStringsSep " " (map (flag: "-Wl,${flag}") linkerFlags)}' \
      --prefix FLUTTER_ALREADY_LOCKED : true \
      --suffix PATH : "${lib.makeBinPath (buildTools)}" \
      --suffix "PUB_CACHE=\$HOME/.pub-cache" \
      --add-flags "--disable-dart-dev" \
      --add-flags "--define=NIX_FLUTTER_HOST_PLATFORM=${stdenv.hostPlatform.system}" \
      --add-flags "--packages=$out/opt/flutter-elinux/.dart_tool/package_config.json" \
      --add-flags "$out/opt/flutter-elinux/bin/cache/flutter-elinux.snapshot"
  '';
}
