{
  self,
  nixpkgs,
  nixpkgs-container-in-vm-patch,
  system,
  ...
}:
let
  # See https://wiki.nixos.org/wiki/Nixpkgs/Patching_Nixpkgs
  # See https://discourse.nixos.org/t/using-changes-from-a-nixpkgs-pr-in-your-flake/60948
  # See https://discourse.nixos.org/t/proper-way-of-applying-patch-to-system-managed-via-flake/21073/26
  nixpkgs' = import nixpkgs { inherit system; };
  nixpkgsPatched' = nixpkgs'.applyPatches {
    name = "nixpkgs-container-in-vm-patch";
    src = nixpkgs;
    patches = [ nixpkgs-container-in-vm-patch ];
  };

  nixpkgsPatched = (import "${nixpkgsPatched'}/flake.nix").outputs { inherit self; };
in
nixpkgsPatched
