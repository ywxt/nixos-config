{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  rkdeveloptool,
}:

stdenvNoCC.mkDerivation {
  pname = "dayu200-flash";
  version = "2026-09-11";

  src = ./flash.py;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/libexec/dayu200-flash/flash.py
    makeWrapper ${lib.getExe python3} $out/bin/dayu200-flash \
      --add-flags $out/libexec/dayu200-flash/flash.py \
      --prefix PATH : ${lib.makeBinPath [ rkdeveloptool ]}

    install -d $out/lib/udev/rules.d
    substitute ${./85-rk3568.rules} $out/lib/udev/rules.d/85-rk3568.rules \
      --replace-fail 'MODE="0666"' 'TAG+="uaccess"'

    runHook postInstall
  '';

  meta = {
    description = "Open-source Linux flashing tool for the HiHope DAYU200 RK3568 board";
    homepage = "https://gitee.com/hihope_iot/docs/tree/master/HiHope_DAYU200";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    mainProgram = "dayu200-flash";
  };
}
