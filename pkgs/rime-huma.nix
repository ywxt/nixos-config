{
  lib,
  stdenvNoCC,
  src,
  version ? "unstable",
}:

stdenvNoCC.mkDerivation {
  pname = "rime-huma";
  inherit src version;

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
