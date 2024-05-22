# Auto-Editor

A Nix-Derivation for [Auto-Editor](https://github.com/WyattBlue/auto-editor).

To build this derivation from the command line for debugging purposes, run

```sh
nix-build -E 'with import <nixpkgs> {}; with pkgs.python310Packages; callPackage ./auto-editor.nix {}'
```
