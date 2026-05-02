{ ... }:
final: prev: {
  # TODO: Remove once merged
  # See https://github.com/NixOS/nixpkgs/issues/512864
  beszel = prev.beszel.overrideAttrs {
    doCheck = false;
    tags = [ ];
  };
}
