{
  cmake,
  fetchFromGitHub,
  gtk4,
  lib,
  pkg-config,
  stable-diffusion-cpp,
  stdenv,
  makeWrapper,
  ...
}:
stdenv.mkDerivation rec {
  pname = "neural-pixel";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "Luiz-Alcantara";
    repo = "Neural-Pixel";
    tag = "v${version}";
    hash = "sha256-uhvfgsCRqzTlbLFou+WE59//69cqRTu4mdjJ4waJWfo=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    makeWrapper
  ];

  buildInputs = [ gtk4 ];

  patchPhase = ''
    sed -i "s@"./sd"@sd-cli@g" src/cmd_generator.c;
    sed -i "s@./resources/@$out/shared/neural-pixel/@g" src/constants.c;
    sed -i "s@resources/@$out/shared/neural-pixel/@g" src/main.c;
  '';

  cmakeFlags = [
    "-DCMAKE_C_FLAGS=-Wno-format-security"
  ];

  installPhase = ''
    mkdir -p $out/shared/neural-pixel;
    install -Dm 755 bin/neural_pixel $out/bin/neural-pixel;
    install -Dm 644 resources/* $out/shared/neural-pixel/;

    wrapProgram $out/bin/neural-pixel \
      --set GTK_THEME Adwaita:dark \
      --suffix PATH : ${lib.makeBinPath [ stable-diffusion-cpp ]};
  '';
}
