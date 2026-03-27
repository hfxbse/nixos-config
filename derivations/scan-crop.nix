{
  imagemagick,
  lib,
  writeShellScriptBin,
  ...
}:
let
  magick = lib.getExe' imagemagick "magick";
in
writeShellScriptBin "scan-crop" ''
  if [ "$#" -ne 2 ]; then
    echo "Usage: $(basename "$0") <input-file> <output-file>";
    exit 1;
  fi

  input="$1";
  output="$2";
  canny=$(mktemp --suffix=".tiff");

  ${magick} "$input" \
    -auto-level \
    -colorspace Gray \
    -canny 0x20+3%+20% \
    -define connected-components:area-threshold=10 \
    "$canny";

  echo "Canny file: $canny";

  BOX=$(
    ${magick} "$canny" \
    -trim \
    -format "%wx%h%O" info:
  );

  H=$(
    ${magick} "$canny" \
    -fill black \
    -draw "rectangle 0,0 200,99999" \
    -draw "rectangle 0,0 99999,5" \
    -trim \
    -format "%h" info:
  );

  BOX=$(
    echo "$BOX" \
    | sed -E "s/x[0-9]+/x''${H}/" \
    | sed -E "s/^([0-9]+)/$(( $(echo "$BOX" | grep -oP '^\d+') - 5 ))/"
  );
  echo "Cropping to $BOX";

  ${magick} "$input" \
    -crop "$BOX" \
    -trim \
    +repage \
    "$output";
''
