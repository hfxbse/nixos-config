{
  latex,
  mainFile ? "main.tex",
  outputDirectory ? ".",
  writeShellScriptBin
}:
writeShellScriptBin "compile-latex" ''
  set -e;

  DOC="$(pwd)/${mainFile}";
  OUT="$(pwd)/${outputDirectory}";
  HELP=false;

  while getopts "f:o:h" OPT; do
    case $OPT in
      f) DOC=$(readlink -f "$OPTARG");;
      h) HELP=true;;
      o) OUT=$(readlink -f "$OPTARG");;
    esac
  done

  if [ $HELP = true ]; then
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

  ${latex}/bin/pdflatex -output-directory="$OUT" "$DOC";
  ${latex}/bin/biber --output-directory="$OUT" "$OUT"/*.bcf;
  ${latex}/bin/pdflatex -output-directory="$OUT" "$DOC";
  ${latex}/bin/pdflatex -output-directory="$OUT" "$DOC";
''
