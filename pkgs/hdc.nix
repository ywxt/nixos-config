{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

let
  version = "26.0.0.38";
  apiVersion = "26";
  apiDir = "opt/ohos-sdk/${apiVersion}";
in
stdenvNoCC.mkDerivation {
  pname = "ohos-hdc";
  inherit version;

  src = fetchurl {
    url = "https://repo.huaweicloud.com/openharmony/os/7.0-Release/ohos-sdk-windows_linux-public.tar.gz";
    hash = "sha256-EwpDjLzd1GoqWwnumSUznN30zKmSIzKbhg+WpccvM48=";
  };

  nativeBuildInputs = [ unzip ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    tar -xzf $src ohos-sdk/linux/toolchains-linux-x64-*.zip
    mkdir -p $out/${apiDir}/toolchains $out/bin $out/lib/udev/rules.d
    unzip -q ohos-sdk/linux/toolchains-linux-x64-*.zip -d $out/${apiDir}
    ln -s $out/${apiDir}/toolchains/hdc $out/bin/hdc
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", ATTR{idProduct}=="5000", TAG+="uaccess"' \
      > $out/lib/udev/rules.d/70-ohos-hdc.rules
    chmod -R u+rwX,go+rX $out/opt

    runHook postInstall
  '';

  meta = {
    description = "OpenHarmony device connector from SDK ${version} (API ${apiVersion})";
    homepage = "https://gitcode.com/openharmony/manifest";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "hdc";
  };
}
