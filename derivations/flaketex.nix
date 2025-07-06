{
  latex,
  writeShellScriptBin,
}:
let
  tools = latex.withPackages (
    texlivePackages: with texlivePackages; [
      biber
      glossaries
    ]
  );
in
writeShellScriptBin "compile-latex" ''
  set -e;

  DOC="$(pwd)/main.tex";
  OUT="$(pwd)";
  HELP=false;

  while getopts "f:o:h" OPT; do
    case $OPT in
      f) DOC=$(readlink -f "$OPTARG");;
      h) HELP=true;;
      o) OUT=$(readlink -f "$OPTARG");;
    esac
  done

  pdflatexOptions=$(echo "$@" |  awk -F'--' '{print $2}');

  if [ $HELP = true ]; then
    echo "Usage";
    echo "compile-latex [OPTIONS ...] [-- PDF_LATEX_OPTIONS]"
    echo "";
    echo "Options";
    echo "-f <PATH>           Path to the main LaTeX file.";
    echo "-h                  Shows this help.";
    echo "-o <PATH>           Compilation output directory path.";
    exit 1;
  fi

  # Mirror the structure of the source directories
  # pdflatex cannot write the output files otherwise
  DOC_DIR=$(dirname $DOC);
  for SRC_DIR in $(find $DOC_DIR -type d -not -path "$OUT*"); do
    mkdir -p "''${SRC_DIR/$DOC_DIR/$OUT}";
  done

  # Required to get relative paths inside LaTeX to work
  cd $DOC_DIR;

  ${tools}/bin/pdflatex $pdflatexOptions -output-directory="$OUT" "$DOC";
  ${tools}/bin/biber --output-directory="$OUT" "$OUT"/*.bcf;

  # makeglossaries might fail gracefully if no glossaires exists
  set +e;
  ${tools}/bin/makeglossaries -d "$OUT" "$(basename "''${DOC%.*}")";
  set -e;

  ${tools}/bin/pdflatex $pdflatexOptions -output-directory="$OUT" "$DOC";
  ${tools}/bin/pdflatex $pdflatexOptions -output-directory="$OUT" "$DOC";
''
