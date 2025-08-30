{
  catch2,
  cmake,
  fetchFromGitHub,
  fmt,
  nlohmann_json,
  range-v3,
  stdenv,
  tl-expected,
  ...
}:
let
  version = "1.13.0";
  dependencies = [
    range-v3
    tl-expected
  ];
in
stdenv.mkDerivation {
  inherit version;
  pname = "skyr-url";

  src = fetchFromGitHub {
    owner = "cpp-netlib";
    repo = "url";
    tag = "v${version}";
    hash = "sha256-f+WcXdvsIGfXUIIK039DP3GS/BzOMbx9lH0G2ZM9NOg=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    catch2
    fmt
    nlohmann_json
  ] ++ dependencies;
  propagatedBuildInputs = dependencies;
}
