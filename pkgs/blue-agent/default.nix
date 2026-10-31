{
  lib,
  stdenvNoCC,
  makeWrapper,
  python3,
  systemd,
}:

# Keep in sync with AGENT_VERSION in agent.py.
let
  # The agent is pure-stdlib Python; loginctl comes from systemd.
  runtimeDeps = [
    python3
    systemd
  ];
in
stdenvNoCC.mkDerivation {
  pname = "blue-agent";
  version = "0.9.21";

  src = ./agent.py;

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
