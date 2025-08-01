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
# everything after the `--` will be passed to the script
nix run github:hfxbse/nixos-config#flaketex -- -h
```

### Quick template

Wrapper around `nix flake init` to avoid having to type long URLs manually.

## Templates

### Baseline flake template

* `.editorconfig` for `.nix` files and enforcing a new line at the end of all files.
* GitHub Workflow to check the validity of the flake.
* `system` helper function only using `nixpkgs.lib.genAttrs`.
* `.gitignore` excluding build output from Nix.

To utilize this template run

```sh
nix flake init -t github:hfxbse/nixos-config
```

## Host configurations

### CGI WSL

WSL2 configuration using [NixOS-WSL](https://github.com/nix-community/NixOS-WSL).

Build an installation file via

```sh
sudo nix run .#nixosConfigurations.cgi-wsl.config.system.build.tarballBuilder
```
