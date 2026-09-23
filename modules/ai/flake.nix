{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    inputs:
    let
      perSystem =
        generator:
        inputs.nixpkgs.lib.genAttrs [
          "x86_64-linux"
        ] (system: generator system inputs.nixpkgs.legacyPackages.${system});
    in
    {
      packages = perSystem (
        system: pkgs:
        let
          callPackage' = file: pkgs.callPackage (import file) { };
          pkgs' = (
            import inputs.nixpkgs {
              inherit system;
              overlays = [ inputs.self.overlays.sdcpp ];
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (inputs.nixpkgs.lib.getName pkg) [
                  "cuda_cccl"
                  "cuda_cudart"
                  "cuda_nvcc"
                  "libcublas"
                  "cuda_nvrtc"
                ];
            }
          );
        in
        {
          neural-pixel = callPackage' ./neural-pixel.nix;
          sdcpp-webui = callPackage' ./sdcpp-webui.nix;
          stable-diffusion-cpp = pkgs'.stable-diffusion-cpp;
          stable-diffusion-cpp-cuda = pkgs'.stable-diffusion-cpp-cuda;
          stable-diffusion-cpp-rocm = pkgs'.stable-diffusion-cpp-rocm;
          stable-diffusion-cpp-vulkan = pkgs'.stable-diffusion-cpp-vulkan;
        }
      );

      overlays.sdcpp =
        final: prev:
        ((import ./stable-diffusion-cpp.nix) final prev)
        // {
          inherit (inputs.self.packages.${prev.stdenv.hostPlatform.system}) sdcpp-webui;
        };
    };
}
