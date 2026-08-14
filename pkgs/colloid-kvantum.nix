{ fetchFromGitHub, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "colloid-kvantum";
  version = "0-unstable-2026-04-03";

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
}
