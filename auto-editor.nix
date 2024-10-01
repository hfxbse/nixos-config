{ lib, python, buildPythonApplication, fetchPypi, fetchFromGitHub, pythonRelaxDepsHook }:
let
  py = python.override {
    packageOverrides = final: prev: {
      av = prev.av.overridePythonAttrs rec {
        pname = prev.av.pname;
        version = "13.0.0";

        src = fetchFromGitHub {
          owner = prev.av.src.owner;
          repo = prev.av.src.repo;
          rev = "refs/tags/v${version}";
          hash = "sha256-blvtHSUqSl9xAM4t+dFJWmXiOjtnAUC9nicMaUY1zuU=";
        };

        # Disable tests that require an internet connection
        disabledTests = [
          "test_pts_assertion_same_rate"
        ] ++ prev.av.disabledTests;
      };
    };
  };
in
buildPythonApplication rec {
  pname = "auto-editor";
  version = "25.3.0";

  src = fetchPypi {
    pname = "auto_editor";
    inherit version;
    hash = "sha256-KlPFOaAK+OCdxXVmw1E1fTUPRRSnIQlK1rauuYz1p3k=";
  };

  format = "pyproject";

  dependencies = with py.pkgs; [ av numpy ];

  build-system = with py.pkgs; [
    setuptools
  ];

  nativeBuildInputs = [ pythonRelaxDepsHook ];
  pythonRemoveDeps = [
    "pyav"
    "ae-ffmpeg"
  ];

  meta = with lib; {
    description = "Auto-Editor: Effort free video editing!";
    homepage = "https://github.com/WyattBlue/auto-editor";
    license = licenses.unlicense;
  };
}
