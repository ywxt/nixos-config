{
  fetchurl,
  lib,
  p7zip,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "th-tshyn";
  version = "5.0.0";

  src = fetchurl {
    url = "http://cheonhyeong.com/File/TH-Tshyn-${finalAttrs.version}.7z";
    hash = "sha256-cqYgRfj3busbxVuQbKYdD+jcx3mDkfUrtFgQDpEdazM=";
  };

  nativeBuildInputs = [ p7zip ];

  unpackPhase = ''
    runHook preUnpack
    7z x -y -aoa "$src"
    runHook postUnpack
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    fontDir="$out/share/fonts/truetype"
    mkdir -p "$fontDir"
    find . -type f \( -iname '*.ttf' -o -iname '*.ttc' \) \
      -exec install -m444 -t "$fontDir" {} +

    runHook postInstall
  '';

  meta = {
    description = "Tianheng full Unicode font collection";
    homepage = "http://cheonhyeong.com/Traditional/download.html";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.all;
  };
})
