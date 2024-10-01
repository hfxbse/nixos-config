# Auto-Editor

A Nix derivation for [Auto-Editor](https://github.com/WyattBlue/auto-editor).

Can be run directly from this repository as [Nix flake](https://wiki.nixos.org/wiki/Flakes).

```sh
nix run github:hfxbse/nixos-config/derivation/auto-editor
```

On systems without enabled flake support, run this instead:

```sh
nix --experimental-features "nix-command flakes" run github:hfxbse/nixos-config/derivation/auto-editor
```
