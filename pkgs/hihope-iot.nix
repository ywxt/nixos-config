{
  lib,
  stdenvNoCC,
  fetchzip,
  autoPatchelfHook,
  python3,
  libusb1,
  gcc-unwrapped,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hihope-iot-dayu200-flash";
  version = "2026-08-11";

  src = fetchzip {
    url = "https://gitee.com/hihope_iot/docs/repository/archive/${finalAttrs.passthru.rev}.tar.gz";
    hash = "sha256-KNrQXKpgmQwkAs+sm8Tr51+3zgc89BOiZZhAddXabyI=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    python3
  ];
  buildInputs = [
    libusb1
    gcc-unwrapped.lib
  ];

  installPhase = ''
    runHook preInstall

    toolDir="$out/libexec/hihope-iot-dayu200-flash"
    mkdir -p "$toolDir/bin" "$out/bin" "$out/lib/udev/rules.d"
    cp "HiHope_DAYU200/烧写工具及指南/linux/flash.py" "$toolDir/"
    cp "HiHope_DAYU200/烧写工具及指南/linux/bin/config.ini" "$toolDir/bin/"
    cp "HiHope_DAYU200/烧写工具及指南/linux/bin/flash.x86_64" "$toolDir/bin/"
    chmod +x "$toolDir/flash.py" "$toolDir/bin/flash.x86_64"
    patchShebangs "$toolDir/flash.py"
    ln -s "$toolDir/flash.py" "$out/bin/dayu200-flash"

    substitute \
      "HiHope_DAYU200/烧写工具及指南/linux/etc/udev/rules.d/85-rk3568.rules" \
      "$out/lib/udev/rules.d/85-rk3568.rules" \
      --replace-fail 'MODE="0666"' 'TAG+="uaccess"'

    runHook postInstall
  '';

  passthru.rev = "99c62c56db5a848b6d259d298e8810594201cd42";

  meta = {
    description = "HiHope Linux flashing tool for the Dayu200 RK3568 board";
    homepage = "https://gitee.com/hihope_iot/docs/tree/master/HiHope_DAYU200";
    license = lib.licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = "dayu200-flash";
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
  };
})
