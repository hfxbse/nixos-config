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

        patches = [];

        # Disable tests that require an internet connection
        disabledTests = [
          "test_pts_assertion_same_rate"
          "test_filter_flush"
          "test_filter_h264_mp4toannexb"
          "test_filter_output_parameters"
          "test_bits_per_coded_sample"
          "test_codec_delay"
          "test_flush_decoded_video_frame_count"
        ] ++ prev.av.disabledTests;

        disabledTestPaths = [
          "tests/test_colorspace.py"
          "tests/test_open.py"
          "tests/test_packet.py"
          "tests/test_streams.py"
          "tests/test_subtitles.py"
        ] ++ [
    	  ( builtins.replaceStrings ["'"] [""] prev.av.disabledTestPaths )
        ];
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
