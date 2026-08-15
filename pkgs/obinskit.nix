{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  writeShellScript,
  writeText,
  makeDesktopItem,
  dejavu_fonts,
  alsa-lib,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libnotify,
  libxkbcommon,
  libxshmfence,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libXt,
  libXtst,
}:

let
  version = "1.2.11";

  app = stdenvNoCC.mkDerivation {
    pname = "obinskit-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://pub-0ff293aefb644607ac910219d9762b50.r2.dev/ObinsKit_${version}_x64.tar.gz";
      hash = "sha256-KhCu1TZsJmcXRSWSTaYOMjt+IA4qqavBwaYzXnkgls0=";
    };

    sourceRoot = "ObinsKit_${version}_x64";
    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt/obinskit $out/share/licenses/obinskit
      cp -r ./* $out/opt/obinskit/
      chmod +x $out/opt/obinskit/obinskit
      install -Dm644 LICENSE.electron.txt \
        $out/share/licenses/obinskit/LICENSE-ELECTRON
      install -Dm644 LICENSES.chromium.html \
        $out/share/licenses/obinskit/LICENSE-CHROMIUM

      runHook postInstall
    '';
  };

  fontConfig = writeText "obinskit-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <dir>${dejavu_fonts}/share/fonts/truetype</dir>
      <cachedir>~/.cache/fontconfig</cachedir>
    </fontconfig>
  '';

  launcher = writeShellScript "obinskit-launch" ''
    unset ELECTRON_RUN_AS_NODE NIXOS_OZONE_WL
    export FONTCONFIG_FILE=${fontConfig}
    exec ${app}/opt/obinskit/obinskit "$@"
  '';

  desktopItem = makeDesktopItem {
    name = "obinskit";
    exec = "obinskit";
    icon = "obinskit";
    desktopName = "ObinsKit";
    genericName = "ObinsKit keyboard configurator";
    categories = [ "Utility" ];
  };

  runtimeDependencies = [
    alsa-lib
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libnotify
    libxkbcommon
    libxshmfence
    mesa
    nspr
    nss
    pango
    systemd
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libXt
    libXtst
  ];
in
buildFHSEnv {
  name = "obinskit";
  inherit version;
  targetPkgs = _: runtimeDependencies;
  runScript = launcher;

  extraInstallCommands = ''
    mkdir -p $out/share/pixmaps
    ln -s ${desktopItem}/share/applications $out/share/applications
    ln -s ${app}/opt/obinskit/resources/icons/tray-darwin@2x.png \
      $out/share/pixmaps/obinskit.png
  '';

  meta = {
    description = "Graphical configurator for Anne Pro and Anne Pro II keyboards";
    homepage = "https://www.hexcore.xyz/obinskit";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "obinskit";
  };
}
