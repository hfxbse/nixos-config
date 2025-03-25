{
  atk,
  buildEnv,
  cairo,
  callPackage,
  clang,
  cmake,
  fetchFromGitHub,
  fetchpatch,
  fetchzip,
  flutter327,
  gdk-pixbuf,
  glib,
  gnumake,
  gtk3,
  harfbuzz,
  lib,
  libepoxy,
  libdeflate,
  libX11,
  makeWrapper,
  mesa,
  ninja,
  pango,
  pkg-config,
  pkgsCross,
  runCommand,
  stdenv,
  symlinkJoin,
  xorgproto,
  which,
  writeShellScriptBin,
  zlib
}:
let
  pname = "flutter-elinux";
  version = "3.27.1";

  flutter = flutter327.wrapFlutter (flutter327.mkFlutter ({
      patches = flutter327.unwrapped.patches;
      enginePatches = flutter327.engine.unwrapped.patches;
    } // (lib.importJSON ./flutter-version.json))
  );

  aarch64 = pkgsCross.aarch64-multiplatform;
  crossClang = aarch64.clangStdenv.cc;
  linker = "${crossClang}/bin/aarch64-unknown-linux-gnu-ld";

  buildTools = [
    clang
    cmake
    gnumake
    ninja
    pkg-config
  ];

  appRuntimeDeps = [
    atk
    cairo
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libdeflate
    libepoxy
    libX11
    pango
  ] ++ (with aarch64; [
    fontconfig
    libdrm
    libGL
    libgbm
    libinput
    libxkbcommon
    systemdLibs
    wayland
  ]);

  # Development packages required for compilation.
  appBuildDeps =
    let
      # https://discourse.nixos.org/t/handling-transitive-c-dependencies/5942/3
      deps = pkg: builtins.filter lib.isDerivation (
        (pkg.buildInputs or [ ]) ++ (pkg.propagatedBuildInputs or [ ])
      );

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
  linkerFlags = (map (pkg: "-rpath,${lib.getOutput "lib" pkg}/lib") appRuntimeDeps);

  artifacts = map ( {
    architecture,
    hash,
    profile,
    patch ? true
  }: ( callPackage (import ./artifact.nix) {
    inherit architecture;
    inherit hash;
    inherit patch;
    inherit profile;
    inherit version;
    engineShortVersion = "cb4b5fff73";
  }) ) [
    {
      architecture = "arm64";
      hash = "sha256-M0IcOoeVtVb02Lx6YVhV4eLhHgc1XEZs1mGNrUr77Ew=";
      profile = "debug";
    }
    {
      architecture = "arm64";
      hash = "sha256-awxmWQ83Sb5b8/djfcJUhMXaLCWdU04Vp/nuPr0jwJk=";
      profile = "profile";
    }
    {
      architecture = "arm64";
      hash = "sha256-yvzV0Bf4QxFLfZvTaONn9q4GQmRRW8GLNtwEjqGeMWg=";
      profile = "release";
    }
    {
      architecture = "common";
      hash = "sha256-KmRa8bdEXoK3PIjYxpEe5IyIXcmjRF55FFjVpXad92I=";
      profile = null;
      patch = false;
    }
    {
      architecture = "x64";
      hash = "sha256-Eqe97gZ3LAwKaBjltC7vFduYKDuhu50BjNyj/xuGoO0=";
      profile = "debug";
    }
    {
      architecture = "x64";
      hash = "sha256-wlRvyucuFACR903/NzkqS9DFGng5LlK5sf3PCpKCQYE=";
      profile = "profile";
    }
    {
      architecture = "x64";
      hash = "sha256-oPtu0/XlrScPoppGzXuitDREEm8ldeCcCEFm9JcRXVM=";
      profile = "release";
    }
  ];

  flutter-elinux = stdenv.mkDerivation {
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
    ] ++ (map ( {url, hash, name, ...}: fetchzip {
      inherit url;
      inherit hash;
      inherit name;
      stripRoot = false;
    } ) ( builtins.fromJSON ( builtins.readFile ./package-sources.json ) ).packages );

    patches = [
      ./patches/disable-precaching.patch
      ./patches/template-copying.patch
      (fetchpatch {
        url = "https://github.com/sony/flutter-elinux/compare/cbc86f6e71e26f20e0f823549d81e1f3cf4a26ae..Losses:flutter-elinux:fbe5d92863a371ce6fccb9dfdff9e4b20b81ab14.diff";
        hash = "sha256-dByKLzCTVFx7AHIxrqOwCwjB7RLL/1TI/r6nVID41gI=";
        stripLen = 1;
        extraPrefix = "flutter-elinux/";
      })
      (fetchpatch {
        url = "https://github.com/sony/flutter-elinux/compare/1df2296fc73a0f66754224aca0b9ea6165970f78...Losses:flutter-elinux:5175f17f1b6eddbe445084b0e91e22f00a321fdf.diff";
        hash = "sha256-bjaBNsrBALWwJuq1FwNYhBhT2oIM874og5OfS2k9XxA=";
        stripLen = 1;
        extraPrefix = "flutter-elinux/";
        revert = true;
      })
      ./patches/cross-compilation-switch.patch
      ./patches/custom-devices.patch
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

      PACKAGE_TARGET=".pub-cache/hosted/pub.dev"
      mkdir -p "$PACKAGE_TARGET";
      mv * "$PACKAGE_TARGET";
      mv "$PACKAGE_TARGET/flutter-elinux" \
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

      cd flutter_tools/;
      flutter pub get --offline;
      cd -;
    '';

    artifactPaths = builtins.concatStringsSep " " artifacts;
    linkerFlags = builtins.concatStringsSep " " (map (flag: "-Wl,${flag}") linkerFlags);
    includeFlags = builtins.concatStringsSep " " includeFlags;
    flutterPkgConfigPath = builtins.concatStringsSep " " (
      builtins.foldl' (
        paths: pkg:
        paths
        ++ (map (directory: "'${pkg}/${directory}/pkgconfig'") [
          "lib"
          "share"
        ])
      ) [ ] pkgConfigPackages
    );

    passAsFile = [
      "artifactPaths"
      "flutterPkgConfigPath"
      "linkerFlags"
      "includeFlags"
    ];

    installPhase = ''
      for path in $(cat $flutterPkgConfigPathPath); do
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

      unlinkFlutter; unlinkFlutter bin;
      unlinkFlutter bin/cache;
      unlinkFlutter bin/cache/artifacts;
      unlinkFlutter bin/cache/artifacts/engine;

      for artifact in $(cat $artifactPathsPath); do
        echo $artifact;
        ln -s $artifact/* $target/flutter/bin/cache/artifacts/engine/;
      done

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

      LINKER_FLAGS=$(cat $linkerFlagsPath);
      INCLUDE_FLAGS=$(cat $includeFlagsPath);

      makeWrapper ${flutter}/bin/dart $out/bin/flutter-elinux \
        --set-default ANDROID_EMULATOR_USE_SYSTEM_LIBS 1 \
        --suffix PKG_CONFIG_PATH : "$FLUTTER_PKG_CONFIG_PATH" \
        --suffix LIBRARY_PATH : '${lib.makeLibraryPath appStaticBuildDeps}' \
        --prefix LD "''\t" '${linker}' \
        --prefix CC "''\t" '${crossClang}/bin/aarch64-unknown-linux-gnu-clang' \
        --prefix CXX "''\t" '${crossClang}/bin/aarch64-unknown-linux-gnu-clang++' \
        --prefix CXXFLAGS "''\t" "$INCLUDE_FLAGS" \
        --prefix CFLAGS "''\t" "$INCLUDE_FLAGS" \
        --prefix LDFLAGS "''\t" "$LINKER_FLAGS" \
        --prefix FLUTTER_ALREADY_LOCKED : true \
        --suffix PATH : "${lib.makeBinPath (buildTools)}" \
        --suffix "PUB_CACHE=\$HOME/.pub-cache" \
        --add-flags "--disable-dart-dev" \
        --add-flags "--define=NIX_FLUTTER_HOST_PLATFORM=${stdenv.hostPlatform.system}" \
        --add-flags "--packages=$out/opt/flutter-elinux/.dart_tool/package_config.json" \
        --add-flags "$out/opt/flutter-elinux/bin/cache/flutter-elinux.snapshot"
    '';
  };
in
flutter-elinux
