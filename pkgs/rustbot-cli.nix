{
  lib,
  fetchgit,
  python3,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "rustbot-cli";
  version = "2.0.0";

  src = fetchgit {
    url = "https://gitcode.com/xuanwu/rustbot-cli.git";
    rev = "v2.0.0";
    hash = "sha256-ncN2gczWulW+5zHvcjoN4wpTfo/sk3rJZZ1jSZm54Yk=";
  };

  cargoHash = "sha256-3orEuBT+wi89wpT5cGNRwb8+xdtL+ymUqvaVTd6k8B0=";

  # Integration tests run the bundled install.py, which requires python3.
  nativeCheckInputs = [ python3 ];

  # Tests mutate process-wide RUSTBOT_HOME/RUSTBOT_SKILL_ROOT and rely on the
  # repo's .cargo/config.toml RUST_TEST_THREADS=1, which the Nix check hook
  # would override with NIX_BUILD_CORES. The CLI also probes a writable HOME
  # before validating arguments, so tests need one in the sandbox.
  dontUseCargoParallelTests = true;
  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  meta = {
    description = "Installer and version manager for RustBot Skills for OpenCode";
    homepage = "https://gitcode.com/xuanwu/rustbot-cli";
    license = lib.licenses.asl20;
    mainProgram = "rust-bot";
    platforms = lib.platforms.all;
  };
}
