{
  buildPythonApplication,
  fetchFromGitHub,
  gradio,
  pnpm_9,
  setuptools,
  ...
}:
buildPythonApplication {
  name = "sd-cpp-webui";

  src = fetchFromGitHub {
    owner = "DaniAndTheWeb";
    repo = "sd.cpp-webui";
    rev = "87e7885eb7c62404f2229b420fac60c367f4fef9";
    hash = "sha256-7dWx7bmVEfcCtCXFOB2ERyQ9mHv4ZV4i7z2nOvVQ/ao=";
  };

  patchPhase = ''
    cat <<EOL >> pyproject.toml

    [project.scripts]
    sd-cpp-webui = "modules.sdcpp_webui:main"
    EOL

    mv sdcpp_webui.py modules/;
  '';

  pyproject = true;
  build-system = [ setuptools ];
  dependencies = [ gradio ];
  pythonRelaxDeps = [ "gradio" ];
}
