# Baseline flake template

* `.editorconfig` for `.nix` files and enforcing a new line at the end of all files.
* GitHub Workflow to check the validity of the flake.
* `system` helper function only using `nixpkgs.lib.genAttrs`.
* `.gitignore` excluding build output from Nix.

To utilize this template run

```sh
nix flake init -t github:hfxbse/nixos-config
```
