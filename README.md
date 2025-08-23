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

### Nixvim

Neovim configuration on all host machines implemented using
[NixVim](https://github.com/nix-community/nixvim).
Can be run as a standalone program, no dependency on NixOS, though
[Nerd Fonts](https://www.nerdfonts.com/) is needed to display icons correctly.

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

### Bootstrapping

1. Disable secure boot in the BIOS of your computer and set it into setup mode.
2. Format the disk from the installer via [disko](https://github.com/nix-community/disko):
   ```sh
   sudo nix --experimental-features "nix-command flakes" \
       run github:nix-community/disko/latest -- \
       --mode destroy,format,mount \
       disk-config.nix
   ```
3. Install NixOS from the configuration flake:
   ```sh
   sudo nixos-install --flake .
   ```
   ⚠️ Secure boot needs to be disabled in the configuration at this point ⚠️
4. Enter the installation via `nixos-enter` and set the password of the normal
   users.
5. Boot into the new NixOS installation
6. Generate secure boot platform keys and enroll them:
   ```sh
   nix run nixpkgs#sbctl -- create-keys
   nix run nixpkgs#sbctl -- enroll-keys
   ```
   ⚠️ Omitting Microsoft's platform keys might brick your system ⚠️
   This has not been an issue on a _Lenovo ThinkPad X12 gen 1._
7. Enabled secure boot within the BIOS of your computer.
8. Setup automatic unlocking of the LUKS's encryption via TPM:
   ```sh
   sudo systemd-cryptenroll --tpm2-device auto --tpm2-pcrs=0+2+7+12 --wipe-slot=tpm2 /dev/X
   ```

### ISO

Minimal live system to create a bootable ISO from with Nix flakes enabled by
default as well as other quality of live improvements for a headless installation.

A parameterized build is possible using the non-flake CLI, for example setting
up an authorized key for an SSH connection can be accomplished via

```sh
nix-build iso.nix --argstr authorizedKey "$(cat ~/.ssh/id_rsa.pub)"
```

### CGI WSL

WSL2 configuration using [NixOS-WSL](https://github.com/nix-community/NixOS-WSL).

Build an installation file via

```sh
sudo nix run .#nixosConfigurations.cgi-wsl.config.system.build.tarballBuilder
```
