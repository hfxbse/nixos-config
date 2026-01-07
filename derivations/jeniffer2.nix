{
  fetchFromGitHub,
  jre,
  lib,
  makeWrapper,
  maven,
  wrapGAppsHook3,
  ...
}:
let
  mono-repo = fetchFromGitHub {
    owner = "fkellner";
    repo = "Jeniffer2";
    rev = "2c4028539ba78d462213deb3f5a21670bc60e339";
    hash = "sha256-WRXRPmDjtroyMEY8it457OX6B9P809jGSecxFsX61TE=";
  };

  dng-reader = maven.buildMavenPackage rec {
    pname = "dng-reader";
    version = "1.1-SNAPSHOT";

    src = "${mono-repo}/dng";

    mvnParameters =
      let
        skipTests = lib.concatStringsSep "," (
          builtins.map (test: "\!${test}") [
            # IllegalStateException Unable to initialize GLFW
            "de.unituebingen.opengl.NonPOTCropTest"
            "de.unituebingen.opengl.OpenGLWrapperTest"
            "de.unituebingen.opengl.ShaderTest"
          ]
        );
      in
      "-Dtest=${skipTests}";

    mvnHash = "sha256-yH8WgDK18eh+J3zyEFPAG8VjRETyIEg1yBT9RaaeMwI=";

    installPhase = ''
      runHook preInstall
      install -Dm644 target/$pname-${version}.jar $out/share/java/${pname}.jar
      runHook postInstall
    '';
  };
in
maven.buildMavenPackage rec {
  pname = "Jeniffer2";
  version = "1.1";

  src = "${mono-repo}/ui";

  mvnHash = "sha256-P9ovCPtvnqMVNhnPPpM9OoQH3AAurMgd/mLAkbUR/H0=";

  mvnFetchExtraArgs = {
    # See https://maven.apache.org/plugins/maven-install-plugin/examples/custom-pom-installation.html
    preBuild = ''
      mvn install:install-file \
        -Dfile=${dng-reader}/share/java/${dng-reader.pname}.jar \
        -Dmaven.repo.local=$out/.m2;
    '';
  };

  nativeBuildInputs = [
    makeWrapper
    wrapGAppsHook3
  ];

  installPhase = ''
    runHook preInstall;

    local outJar=$out/share/${pname}/${pname}.jar;

    mkdir -p $out/bin;

    install \
      -Dm644 \
      target/${pname}-${version}-jar-with-dependencies.jar \
      $outJar;

    makeWrapper ${jre.override { enableJavaFX = true; }}/bin/java \
      $out/bin/${pname} --add-flags "-jar $outJar";

    runHook postInstall
  '';

  meta = {
    description = "Open Source DNG processor for experimenting with Demosaicing Algorithms - in Java!";
    homepage = "https://github.com/fkellner/jeniffer2";
    license = lib.licenses.free;
    mainProgram = pname;
    meta.platforms = lib.platforms.all;
  };
}
