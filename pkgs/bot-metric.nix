{
  lib,
  fetchgit,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "bot-metric";
  version = "1.2.3";

  src = fetchgit {
    url = "https://gitcode.com/xuanwu/bot-metric.git";
    rev = "v1.2.3";
    hash = "sha256-4GfS/0T+TL0UO+4enQif7P3Q/66U614v+RCpebCFeeg=";
  };

  cargoHash = "sha256-JRGBOJyRvlgmZAW/wI4ArSVYTM2FnsXT2Lka++LO3PA=";

  # The diagnostic catalog test asserts pointer identity of static
  # descriptors, which is not guaranteed in release builds that use
  # multiple codegen units.
  checkFlags = [ "--skip diagnostic_codes_are_stable_and_unique" ];

  meta = {
    description = "Rust source metrics and quality analysis";
    homepage = "https://gitcode.com/xuanwu/bot-metric";
    license = lib.licenses.asl20;
    mainProgram = "bot-metric";
    platforms = lib.platforms.all;
  };
}
