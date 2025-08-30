{
  fetchFromGitHub,
  stdenv,
  ...
}:
let
  version = "2.rc.08";
in
stdenv.mkDerivation {
  inherit version;
  pname = "cpp-base64";

  src = fetchFromGitHub {
    owner = "ReneNyffenegger";
    repo = "cpp-base64";
    tag = "V${version}";
    hash = "sha256-6O0nmrC4pnzN4R3TOLCd+8cyje/n8mpCXX4lDYlXnHE=";
  };
  dontBuild = true;
  checkPhase = ''
    make test;
  '';

  installPhase = ''
    INSTALL_DIR="$out/include/cpp-base64";
    mkdir -p "$INSTALL_DIR";
    cp base64.* "$INSTALL_DIR/"
    chmod 444 "$INSTALL_DIR"/*;
  '';
}
