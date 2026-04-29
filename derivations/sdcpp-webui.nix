{
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpmConfigHook,
  pnpm,
  stdenv,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "sdcpp-webui";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "leejet";
    repo = "sdcpp-webui";
    rev = "797ccf80825cc035508ba9b599b2a21953e7f835";
    hash = "sha256-j/DAhXl8x0IPwEQoxT4GeQ8KCpBh/otS0NWh8GhiElU=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-ocImnMPFHhnuJj3gUN8WsfSur/peLIKiozpPDHU1tAA=";
  };

  buildPhase = ''
    runHook preBuild

    pnpm build
    pnpm build:header

    runHook postBuild
  '';

  installPhase = ''
    cp -r dist/ $out/;
  '';
})
