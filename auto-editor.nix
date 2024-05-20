{ lib, python, buildPythonApplication, fetchPypi, fetchFromGitHub }:
let
  py = python.override {
    packageOverrides = final: prev: {
      av = prev.av.overridePythonAttrs rec {
	pname = prev.av.pname;
	version = "12.0.5";

	src = fetchFromGitHub {
	  owner = prev.av.src.owner;
	  repo = prev.av.src.repo;
	  rev = "v${version}";
	  hash = "sha256-+xbVkNyFg5VKIf+G6AbAAYVqTSwxFE0Hyc52XSmibAw=";
	};

        # Disable tests that require an internet connection
        pytestFlagsArray = [
	  "--deselect=tests/test_codec_context.py::TestCodecContext::test_bits_per_coded_sample"
	  "--deselect=tests/test_codec_context.py::TestCodecContext::test_codec_delay"
	  "--deselect=tests/test_codec_context.py::TestCodecContext::test_frame_index"
	  "--deselect=tests/test_colorspace.py::TestColorSpace::test_penguin_joke"
	  "--deselect=tests/test_colorspace.py::TestColorSpace::test_sky_timelapse"
	  "--deselect=tests/test_decode.py::TestDecode::test_decode_close_then_use"
	  "--deselect=tests/test_decode.py::TestDecode::test_flush_decoded_video_frame_count"
	] ++ prev.av.pytestFlagsArray;

	disabledTestPaths = [
	  "tests/test_open.py"
	  "tests/test_packet.py"
	  "tests/test_streams.py"
	] ++ [
	  # prev.av.disabledTestPaths gets returned as a string
	  # Removing the quotes around the entries fixes this when placing it in an array
	  ( builtins.replaceStrings ["'"] [""] prev.av.disabledTestPaths )
	];
      };
    };
  };
in
buildPythonApplication rec {
  pname = "auto-editor";
  version = "24.19.1";

  src = fetchPypi {
    pname = "auto_editor";
    inherit version;
    hash = "sha256-SFPshD9LTBR2osElFkHTXKsJPWqpOWyLFtGUuTVtQDE=";
  };

  format = "pyproject";

  propagatedBuildInputs = with py.pkgs; [ av numpy setuptools ];

  meta = with lib; {
    description = "Auto-Editor: Effort free video editing!";
    homepage = "https://github.com/WyattBlue/auto-editor";
    license = licenses.unlicense;
  };
}
