{
  lib,
  clippy,
  fetchgit,
  git,
  perl,
  python3,
  rustPlatform,
  rustfmt,
}:

rustPlatform.buildRustPackage {
  pname = "bot-gate";
  version = "1.3.3";

  src = fetchgit {
    url = "https://gitcode.com/xuanwu/bot-gate.git";
    rev = "v1.3.3";
    hash = "sha256-AcXDurDOPXIGk0a5ItHJKXsUdLlbTCnZ4E1HC926pgo=";
  };

  cargoHash = "sha256-BtChpvi4VNWozShK9wlQVMqDcZ6X6KxZIdsczyL1edY=";

  # The clippy fixture locks libc 0.2.189, which is not part of the vendored
  # dependency set (0.2.186); align version and checksum so the fixture
  # builds offline.
  postPatch = ''
    substituteInPlace tests/fixtures/botgate-minimal-clippy/Cargo.lock \
      --replace-fail '3eaf3ede3fee6db1a4c2ee091bf8a8b4dccdc6d17f656fb07896ee72867612f2' '68ab91017fe16c622486840e4c83c9a37afeff978bd239b5293d61ece587de66' \
      --replace-fail 'version = "0.2.189"' 'version = "0.2.186"'
  '';

  # Integration tests run real cargo clippy, cargo fmt, git, and python
  # fixtures; the release workflow tests execute scripts/validate-*.sh,
  # which use perl.
  nativeCheckInputs = [
    clippy
    git
    perl
    python3
    rustfmt
  ];

  # The badplatform sub-case advertises ["linux", "windows-msvc"] and expects
  # the contract to be rejected, which only holds on a macOS host.
  checkFlags = [ "--skip metric_component_info_forged_contracts_block_run_path" ];

  # The Nix builder may run with stdout attached to a PTY whose winsize is
  # zeroed; crossterm then reports terminal width 0 (clamped to 20) and the
  # UI golden tests render the compact layout instead of the expected one.
  # Force a sane winsize; the redirect fails harmlessly when stdout is a
  # plain pipe.
  preCheck = ''
    stty rows 24 cols 100 <&1 > /dev/null 2>&1 || true
  '';

  meta = {
    description = "CI/CD quality gate tool for Rust projects and workspaces";
    homepage = "https://gitcode.com/xuanwu/bot-gate";
    license = lib.licenses.asl20;
    mainProgram = "bot-gate";
    platforms = lib.platforms.all;
  };
}
