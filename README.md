# FlakeTeX

A script to compile a LaTeX project via `pdflatex` provided by [TeX Live](https://tug.org/texlive/).

Has to be run as [Nix flake](https://wiki.nixos.org/wiki/Flakes).

```sh
nix run github:hfxbse/nixos-config/derivation/flaketex
```

Parameters to the script can be pass after a `--` as typical for flakes.
Here is an example which will display the script help.

```sh
# everything after the `--` will be passed to the executed script or program
nix run github:hfxbse/nixos-config/derivation/flaketex -- -h
```

`pdflatex` or `biber` can be executed separtly by specifing them after the `#`.

```sh
nix run github:hfxbse/nixos-config/derivation/flaketex#biber -- -h
```
