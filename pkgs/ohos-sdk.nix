{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  unzip,
  writeShellScript,
  gcc,
  zlib,
  nodejs,
}:

let
  version = "26.0.0.38";
  apiVersion = "26";
  apiDir = "opt/ohos-sdk/${apiVersion}";

  sdk = stdenvNoCC.mkDerivation {
    pname = "ohos-sdk-unwrapped";
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

      tar -xzf $src ohos-sdk/linux manifest_tag.xml
      mkdir -p $out/${apiDir}
      for z in ohos-sdk/linux/*.zip; do
        unzip -q "$z" -d $out/${apiDir}
      done
      install -Dm644 manifest_tag.xml $out/${apiDir}/manifest_tag.xml
      chmod -R u+rwX,go+rX $out/opt

      runHook postInstall
    '';

    passthru = {
      inherit apiVersion apiDir;
    };

    meta = {
      description = "OpenHarmony SDK (Linux x86_64): native cross toolchain, toolchains, ets, js and previewer";
      homepage = "https://gitcode.com/openharmony/manifest";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };

  entry = writeShellScript "ohos-sdk-entry" ''
    export OHOS_SDK_HOME=${sdk}/opt/ohos-sdk
    export OHOS_NDK_HOME=${sdk}/${apiDir}/native
    export OHOS_API_VERSION=${apiVersion}
    export PATH=${sdk}/${apiDir}/native/llvm/bin:${sdk}/${apiDir}/toolchains:$PATH
    exec bash -i "$@"
  '';
in
buildFHSEnv {
  name = "ohos-sdk";
  inherit version;
  targetPkgs = _: [
    gcc.cc.lib
    zlib
    nodejs
  ];
  runScript = entry;

  passthru = {
    inherit sdk;
  };

  meta = {
    description = "OpenHarmony SDK ${version} (API ${apiVersion}) in a FHS-compatible environment";
    homepage = "https://gitcode.com/openharmony/manifest";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ohos-sdk";
  };
}
