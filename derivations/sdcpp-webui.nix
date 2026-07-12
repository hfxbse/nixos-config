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
    owner = "hfxbse";
    repo = "sdcpp-webui";
    rev = "6cdbbd81a679327deccc890e62f00074149319d7";
    hash = "sha256-6FKO/YXmxv6jL1JTpeGmbUQdHPZdjZjRXjHOmC0AmI4=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-3qClrdOxD+J4p4xjTEwevMRKEg2Uhb/U7bTO5smAWio=";
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
