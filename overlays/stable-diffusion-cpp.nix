{ ... }:
final: prev: {
  stable-diffusion-cpp = prev.stable-diffusion-cpp.overrideAttrs (
    finalAttrs: prevAttrs: rec {
      version = "master-589-f40a707";

      src = prev.fetchFromGitHub {
        owner = "leejet";
        repo = "stable-diffusion.cpp";
        tag = version;
        hash = "sha256-mIUBAht6OkWu5QaJeojmlJeMQ2sZwMRUutzh+4ufIZs=";
        fetchSubmodules = true;
      };

      cmakeFlags = prevAttrs.cmakeFlags ++ [
        "-DSDCPP_BUILD_VERSION=${version}"
      ];

      # Use prepbuild frontend
      patchPhase = ''
        cp -r ${final.sdcpp-webui} examples/server/frontend/dist
      '';

      meta.mainProgram = "sd-server";
    }
  );
}
