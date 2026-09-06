{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "colloid-kvantum";
  version = "0-unstable-2025-07-06";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "Colloid-kde";
    rev = "b768904d10ba9fcb95abfb59538eab100b1fed1e";
    hash = "sha256-CWa6HnMP042jh573/x7WxYyRScN/l+jjCasiaBODljA=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/Kvantum"
    cp -R Kvantum/Colloid Kvantum/ColloidNord "$out/share/Kvantum/"
    runHook postInstall
  '';

  meta = {
    description = "Colloid color schemes for the Kvantum Qt theme engine";
    homepage = "https://github.com/vinceliuice/Colloid-kde";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
