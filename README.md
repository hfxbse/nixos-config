# Nix Derivations and OS configurations

Collection of system configurations and derivations for packages not found in
[Nixpkgs](https://search.nixos.org), accessible via a [Nix flake](https://wiki.nixos.org/wiki/Flakes).

## Derivations

### FlakeTeX

A script to compile a LaTeX project via `pdflatex` provided by [TeX Live](https://tug.org/texlive/).

```sh
nix run github:hfxbse/nixos-config#flaketex
```

Parameters to the script can be pass after a `--` as typical for flakes.
Here is an example which will display the script help.

```sh
# everything after the `--` will be passed to the executed script or program
nix run github:hfxbse/nixos-config#flaketex -- -h
```

### Quick template

Wrapper around `nix flake init` to avoid having to type long URLs manually.
