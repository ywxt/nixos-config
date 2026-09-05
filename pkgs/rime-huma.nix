{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "rime-huma";
  version = "0-unstable-2026-05-21";

  src = fetchFromGitHub {
    owner = "ywxt";
    repo = "rime-huma";
    rev = "6657afe00b250f83a38f7de14c85336fb747de6d";
    hash = "sha256-B2lqx13BQpPhn+yhQ3TapALab0hiMundopriyIRVOnk=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/rime-data"
    cp -R . "$out/share/rime-data"
    rm -rf \
      "$out/share/rime-data/.github" \
      "$out/share/rime-data/hotfix"

    runHook postInstall
  '';

  meta = {
    description = "Huma input schema for Rime";
    homepage = "https://github.com/ywxt/rime-huma";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
