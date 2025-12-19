{
  btrfs-progs,
  lib,
  writeShellScriptBin,
  ...
}:
writeShellScriptBin "by-disk-snapshotter" ''
  clean=0;
  dry=0;

  while getopts ":cd" opt; do
    case $opt in
      t) target="$OPTARG"
      ;;
      c) clean=1
      ;;
      d) dry=1
      ;;
      \?) echo "Invalid option -$OPTARG" >&2
      exit 1
      ;;
    esac

    case $OPTARG in
      -*) echo "Option $opt needs a valid argument"
      exit 1
      ;;
    esac
  done

  set -euo pipefail;

  shift $(expr "$OPTIND" - 1);
  target=$1;
  shift;

  for volumePath in "$@"; do
    blk="$(df "$volumePath" --output=source | tail -n 1 | sed 's@^/dev@@' | sed 's@^/mapper@@')";
    volumeName=$(echo $volumePath | sed "s@^/mnt@@");
    volumeTarget=$(echo "$target/$blk/$volumeName" | sed 's@/\+@/@'g | sed 's@/$@@' | sed "s@$blk\$@@");

    if [ "$clean" -eq 0 ]; then
      echo "Creating a read-only BTRFS volume snapshot of $volumePath at $volumeTarget";

      if [ "$dry" -eq 0 ]; then
        mkdir -p "$(dirname "$volumeTarget")";
        ${lib.getExe btrfs-progs} subvolume snapshot -r "$volumePath" $volumeTarget;
      fi
    else
      echo "Deleting a read-only BTRFS volume snapshot of $volumePath at $volumeTarget";

      if [ "$dry" -eq 0 ]; then
        ${lib.getExe btrfs-progs} subvolume delete "$volumeTarget";
      fi
    fi
  done
''
