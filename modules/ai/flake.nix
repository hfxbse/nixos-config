{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    lightpanda = {
      url = "github:crayonnova/lightpanda-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      perSystem =
        generator:
        inputs.nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-darwin"
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
              overlays = [
                inputs.lightpanda.overlays.default
                inputs.self.overlays.sdcpp
              ];

              config.allowUnfreePredicate =
                pkg:
                builtins.elem (inputs.nixpkgs.lib.getName pkg) [
                  "cccl"
                  "cuda_crt"
                  "cuda_cudart"
                  "cuda_nvcc"
                  "cuda_nvrtc"
                  "libcublas"
                  "libnvvm"
                ];
            }
          );
        in
        {
          neural-pixel = callPackage' ./neural-pixel.nix;
          opencode = pkgs'.callPackage (import ./opencode.nix) { llama-cpp = pkgs'.llama-cpp-vulkan; };
          sdcpp-webui = callPackage' ./sdcpp-webui.nix;
          stable-diffusion-cpp = pkgs'.stable-diffusion-cpp;
          stable-diffusion-cpp-vulkan = pkgs'.stable-diffusion-cpp-vulkan;
        }
        // inputs.nixpkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          stable-diffusion-cpp-cuda = pkgs'.stable-diffusion-cpp-cuda;
          stable-diffusion-cpp-rocm = pkgs'.stable-diffusion-cpp-rocm;
        }
      );

      overlays.sdcpp =
        final: prev:
        ((import ./stable-diffusion-cpp.nix) final prev)
        // {
          inherit (inputs.self.packages.${prev.stdenv.hostPlatform.system}) sdcpp-webui;
        };

      devShells = perSystem (
        system: pkgs: {
          ai = pkgs.mkShell {
            packages = with pkgs; [
              inputs.self.packages.${system}.stable-diffusion-cpp-vulkan
              llama-cpp-vulkan
              mcp-searxng
              openssl
              searxng
            ];

            shellHook =
              let
                mkEnvVars = env: inputs.nixpkgs.lib.mapAttrsToList (key: value: "${key}='${toString value}'") env;
                restartExec =
                  {
                    cmd,
                    env ? { },
                  }:
                  ''
                    pkill -f '${cmd}' || true
                    ${builtins.concatStringsSep " " (mkEnvVars env)} nohup ${cmd} > $LOG 2>&1 &
                  '';
              in
              ''
                export LOG=$(mktemp)
                export SEARXNG_SETTINGS_PATH=$(mktemp)

                echo "Writing server logs to $LOG"
                echo "SearXNG settings path: $SEARXNG_SETTINGS_PATH"

                cat > $SEARXNG_SETTINGS_PATH << EOF
                  use_default_settings: true
                  server:
                    secret_key: "$(openssl rand -base64 32)"
                    bind_address: "localhost"
                    port: 8088
                  search:
                    formats:
                      - html
                      - json
                EOF

                ${restartExec {
                  cmd = "searxng-run";
                }}

                ${restartExec {
                  cmd = "mcp-searxng";
                  env = {
                    SEARXNG_URL = "http://localhost:8088";
                    MCP_HTTP_PORT = 8089;
                    MCP_HTTP_ALLOWED_ORIGINS = "http://localhost:8080";
                  };
                }}
              '';
          };
        }
      );
    };
}
