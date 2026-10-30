{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
  coreutils,
  curl,
  gawk,
  gnused,
  jq,
  systemd,
}:

# Keep in sync with AGENT_VERSION in agent.sh.
let
  # loginctl comes from systemd; everything else is standard CLI tooling.
  runtimeDeps = [
    bash
    coreutils
    curl
    gawk
    gnused
    jq
    systemd
  ];
in
stdenvNoCC.mkDerivation {
  pname = "blue-agent";
  version = "1.0.0";

  src = ./agent.sh;

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm555 $src $out/bin/blue-agent
    wrapProgram $out/bin/blue-agent --prefix PATH : ${lib.makeBinPath runtimeDeps}
    runHook postInstall
  '';

  meta = {
    description = "BlueZone asset heartbeat agent (unprivileged Linux port of agent.ps1)";
    license = lib.licenses.mit;
    mainProgram = "blue-agent";
    platforms = lib.platforms.linux;
  };
}
