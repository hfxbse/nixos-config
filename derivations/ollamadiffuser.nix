{
  lib,
  buildPythonApplication,
  buildPythonPackage,
  cmake,
  fetchFromGitHub,
  fetchPypi,
  setuptools,
  torch,
  diffusers,
  transformers,
  accelerate,
  fastapi,
  gguf,
  uvicorn,
  huggingface-hub,
  pillow,
  click,
  rich,
  pydantic,
  protobuf,
  safetensors,
  sentencepiece,
  python-multipart,
  psutil,
  jinja2,
  peft,
  numpy,
  ninja,
  mcp,
  opencv-python,
  requests,
  pyyaml,
  importlib-metadata,
  scipy,
  opencv-python-headless,
  filelock,
  einops,
  torchvision,
  timm,
  scikit-build-core,
  scikit-image,
  stable-diffusion-cpp,
  typing-extensions,
  ...
}:
let
  controlnet-aux = buildPythonPackage rec {
    pname = "controlnet-aux";
    version = "0.0.10";

    pyproject = true;

    src = fetchPypi {
      inherit version;
      pname = "controlnet_aux";
      hash = "sha256-MdwmWlREi9zuAzoTC0dCPIBYf6NcysdSETrxtNSPUYM=";
    };

    propagatedBuildInputs = [
      torch
      huggingface-hub
      numpy
      pillow
    ];

    buildInputs = [
      setuptools
      importlib-metadata
      scipy
      opencv-python-headless
      filelock
      einops
      torchvision
      timm
      scikit-image
    ]
    ++ propagatedBuildInputs;
  };

  stable-diffusion-cpp-python = buildPythonPackage rec {
    pname = "stable-diffusion-cpp-python";
    version = "0.4.5";

    pyproject = true;

    src = fetchPypi {
      inherit version;
      pname = "stable_diffusion_cpp_python";
      hash = "sha256-uFoelR3uD44Ivt4TE6WttvJzivGrY85l0h4IzVpzSDo=";
    };

    propagatedBuildInputs = [
      typing-extensions
      pillow
      stable-diffusion-cpp
    ];

    nativeBuildInputs = [
      cmake
      ninja
      scikit-build-core
    ];

    dontUseCmakeConfigure = true;
    cmakeFlags = [ "-DSTABLE_DIFFUSION_BUILD=OFF" ];
  };
in
buildPythonApplication rec {
  name = "ollamadiffuser";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "LocalKinAI";
    repo = name;
    rev = "80487e4158572756e9fc71345e45f6a53f7809d6";
    hash = "sha256-E0WWxljdHkW2gpE89j/HQf5BlJpjgwq9SagqUPv2kz8=";
  };

  nativeBuildInputs = [ setuptools ];

  makeWrapperArgs = [
    "--set STABLE_DIFFUSION_CPP_LIB ${stable-diffusion-cpp}/lib/libstable-diffusion.so"
  ];

  propagatedBuildInputs = [
    click
    diffusers
    transformers
    accelerate
    fastapi
    gguf
    mcp
    uvicorn
    rich
    pydantic
    protobuf
    safetensors
    sentencepiece
    stable-diffusion-cpp-python
    python-multipart
    psutil
    jinja2
    peft
    controlnet-aux
    opencv-python
    requests
    pyyaml
  ];
}
