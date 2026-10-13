final: prev: {
  stable-diffusion-cpp = prev.stable-diffusion-cpp.overrideAttrs (
    finalAttrs: prevAttrs: rec {
      version = "master-956-1b0ba10";

      src = prev.fetchFromGitHub {
        owner = "leejet";
        repo = "stable-diffusion.cpp";
        tag = version;
        hash = "sha256-EADt1ViQtbwFB0PgxsTCKnbyQ7+nlQB32h9eaDYijfk=";
        fetchSubmodules = true;
      };

      cmakeFlags = prevAttrs.cmakeFlags ++ [
        "-DSDCPP_BUILD_VERSION=${version}"
      ];

      # Use prebuild frontend
      patchPhase = ''
        cp -r ${final.sdcpp-webui} examples/server/frontend/dist
      '';

      meta.mainProgram = "sd-server";
    }
  );
}
