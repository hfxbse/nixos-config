{ ... }:
final: prev: {
  # TODO: Remove once merged
  # See https://github.com/NixOS/nixpkgs/pull/477694
  sieve-editor-gui = prev.sieve-editor-gui.override {
    buildNpmPackage = prev.buildNpmPackage.override { nodejs = prev.nodejs_22; };
  };
}
