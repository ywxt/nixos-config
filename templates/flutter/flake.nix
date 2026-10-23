# Flutter + Android dev shell.
#
# The SDK carries exactly two platforms: the minimum Android version the
# project supports (chosen: Android 10; Flutter's own floor is API 24, so
# lower it here if an older runtime is really needed) and the recommended
# one (flutter.compileSdkVersion), each with a matching AVD provisioned
# into the project-local .avd/ directory on first entry. Inside the shell,
# `flutter create .` bootstraps a project and `flutter run` deploys to a
# device or the emulator.
{
  description = "Flutter and Android development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      # Android SDK binaries and flutter's Android engine artifacts are
      # x86_64-only, so there is no point exposing other systems.
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true; # Android SDK components are unfree
              # Accepted license hashes are written into the SDK at build
              # time, so `flutter doctor --android-licenses` passes without
              # prompts (the store path is read-only afterwards).
              android_sdk.accept_license = true;
            };
          };
          inherit (pkgs) lib;

          # ── Adjust to your project ─────────────────────────────────────
          # Exactly two platforms are kept: the minimum Android version the
          # project supports and the API level projects compile against
          # (flutter.compileSdkVersion). Every platform also pulls one
          # system image per type × ABI below (> 1 GB each), so keep these
          # lists tight.
          platformVersions = [
            "29" # Android 10, chosen minimum (flutter.minSdkVersion is 24)
            "36" # flutter.compileSdkVersion / targetSdkVersion (Android 16)
          ];

          # Build-tools versions AGP may request; its default depends on
          # the AGP version (9.x → 36.0.0, 8.x → 35.0.0).
          buildToolsVersions = [
            "35.0.0"
            "36.0.0"
          ];

          # NDK, for projects with native code (flutter_rust_bridge etc.).
          # Requires BOTH the version list and includeNDK = true below.
          # Flutter 3.47 pins 28.2.13676358.
          ndkVersions = [ ];

          # System images: the defaults would fetch every type × ABI
          # combination, so pin exactly what the AVDs below use.
          systemImageTypes = [ "google_apis" ];
          abiVersions = [ "x86_64" ];

          # AVDs provisioned automatically on first entry, one per platform
          # above. `avdmanager list device` prints all available device ids;
          # each `package` must match an image included above.
          avds = [
            {
              name = "Pixel_7_API_29";
              device = "pixel_7";
              package = "system-images;android-29;google_apis;x86_64";
            }
            {
              name = "Pixel_7_API_36";
              device = "pixel_7";
              package = "system-images;android-36;google_apis;x86_64";
            }
          ];

          # Also build for the Linux desktop target (`flutter run -d linux`).
          linuxDesktop = true;
          # ─────────────────────────────────────────────────────────────────

          jdk = pkgs.jdk; # AGP 8/9 requires JDK 17+

          androidSdk =
            (pkgs.androidenv.composeAndroidPackages {
              inherit
                platformVersions
                buildToolsVersions
                ndkVersions
                systemImageTypes
                abiVersions
                ;
              includeEmulator = true;
              includeSystemImages = true;
              # The composition writes license hash files at build time (the
              # store path is read-only, so `flutter doctor --android-licenses`
              # cannot accept anything later). Only android-sdk-license is
              # written by default, but sdkmanager — which flutter doctor runs
              # to validate licenses — requires the hashes of every license
              # referenced by the repository, otherwise it reports
              # "Some Android licenses not accepted". These names cover all
              # licenses known to androidenv's repo.json.
              extraLicenses = [
                "android-sdk-arm-dbt-license"
                "android-sdk-preview-license"
                "android-googletv-license"
                "android-googlexr-license"
                "google-gdk-license"
                "intel-android-extra-license"
                "intel-android-sysimage-license"
                "microxr-sysimage-license"
                "mips-android-sysimage-license"
              ];
            }).androidsdk;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.flutter # bundles dart + engine artifacts; PUB_CACHE → ~/.pub-cache
              pkgs.git # required by the flutter tool itself
              androidSdk # adb, sdkmanager, avdmanager, emulator on PATH
              jdk
            ]
            ++ lib.optionals linuxDesktop [
              # `flutter run -d linux` build dependencies
              pkgs.clang
              pkgs.cmake
              pkgs.libepoxy
              pkgs.ninja
              pkgs.pcre
              pkgs.pkg-config
              pkgs.gtk3
            ];

            JAVA_HOME = jdk.home;
            ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk"; # legacy tools still read this

            shellHook = ''
              # AGP downloads an unpatched aapt2 from Maven, which cannot
              # run on NixOS. Point Gradle at the auto-patched copy inside
              # the SDK (newest build-tools wins).
              aapt2="$(ls -d "$ANDROID_HOME"/build-tools/*/aapt2 | sort -V | tail -1)"
              export GRADLE_OPTS="''${GRADLE_OPTS:-} -Dorg.gradle.project.android.aapt2FromMavenOverride=$aapt2"

              # AVDs are project-level: they live in .avd/ at the project
              # root (git toplevel, falling back to the working directory)
              # instead of ~/.android/avd. Set ANDROID_AVD_HOME to override.
              project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
              export ANDROID_AVD_HOME="''${ANDROID_AVD_HOME:-$project_root/.avd}"
              mkdir -p "$ANDROID_AVD_HOME"

              # Create declared AVDs that do not exist yet.
              ${lib.concatMapStrings (avd: ''
                if [ ! -d "$ANDROID_AVD_HOME/${avd.name}.avd" ]; then
                  echo "Creating AVD ${avd.name}..."
                  echo no | avdmanager create avd -n "${avd.name}" -k "${avd.package}" -d "${avd.device}"
                fi
              '') avds}
            '';
          };
        }
      );
    };
}
