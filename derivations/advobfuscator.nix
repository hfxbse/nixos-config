{
  fetchFromGitHub,
  stdenv,
  ...
}:
let
  rev = "1852a0eb75b03ab3139af7f938dfb617c292c600";
in
stdenv.mkDerivation {
  name = "advobfuscator-legacy";

  src = fetchFromGitHub {
    owner = "andrivet";
    repo = "ADVobfuscator";
    inherit rev;
    hash = "sha256-qleFYWPmCYHHtBO3Op3e8T6fxmC/3KwpatcQ8keiiz8=";
  };

  dontBuild = true;

  installPhase = ''
    INSTALL_DIR="$out/include/advobfuscator/Lib";
    mkdir -p "$INSTALL_DIR";
    cp Lib/* "$INSTALL_DIR/"
    chmod 444 "$INSTALL_DIR"/*;
  '';
}
