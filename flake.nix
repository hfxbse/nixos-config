{
  description = "FlakeTeX: TexLive distrubited as Nix flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};

    # Refer to the NixOS on how to customize the TexLive installation
    # https://wiki.nixos.org/wiki/TexLive
    latex = pkgs.texliveFull;
  in
  {
    packages.compile-latex = pkgs.writeShellScriptBin "compile-latex" ''
      set -e

      DOC="$(pwd)/main.tex";
      OUT=$(pwd);
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
        echo "-f <PATH>           File path to the LaTeX document entry point.";
        echo "-h                  Shows this help.";
        echo "-o <PATH>           Compilation output directory path.";
        exit 1;
      fi

      DOC_DIR=$(dirname $DOC);
      for SRC_DIR in $(find $DOC_DIR -type d -not -path "$OUT*"); do
        mkdir -p "''${SRC_DIR/$DOC_DIR/$OUT}";
      done

      ${latex}/bin/pdflatex -output-directory="$OUT" "$DOC";
      ${latex}/bin/biber --output-directory="$OUT" "$OUT"/*.bcf;
      ${latex}/bin/pdflatex -output-directory="$OUT" "$DOC";
      ${latex}/bin/pdflatex -output-directory="$OUT" "$DOC";
    '';

    packages.default = self.packages.${system}.compile-latex;

    apps = {
      pdflatex = {
        type = "app";
        program = "${latex}/bin/pdflatex";
      };

      pdftex = self.apps.${system}.pdflatex;

      biber = {
        type = "app";
        program = "${latex}/bin/biber";
      };
    };
  });
}
