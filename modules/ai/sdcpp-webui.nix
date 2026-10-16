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
    rev = "45b2b01d3f0ca2fc5b464efb0f6e381bc55b083b";
    hash = "sha256-tMYXaQVEHSYgPyAzI8R2MSbh4s3/quJrVmvkOmTD6kY=";
  };

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash =
      if stdenv.hostPlatform.isDarwin then
        "sha256-hMhCBy7t4UMOJwqzix8FCqZvQniCyKk5JXf1Gvb3/mY="
      else
        "sha256-rdUNxeEojJYcbNqr8a+2UQQgVq8bGIKTmM/3eOxn45I=";
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
