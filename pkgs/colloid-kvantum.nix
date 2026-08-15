{
  src,
  stdenvNoCC,
  version ? "unstable",
}:

stdenvNoCC.mkDerivation {
  pname = "colloid-kvantum";
  inherit src version;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/Kvantum"
    cp -R Kvantum/Colloid Kvantum/ColloidNord "$out/share/Kvantum/"
    runHook postInstall
  '';
}
