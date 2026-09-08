{ pkgs, ... }:

{
  /*
    OpenHarmony 7.0 Dayu200/RK3568 full-system source build:

      mkdir -p "$HOME/src/openharmony-7.0"
      cd "$HOME/src/openharmony-7.0"

      repo init -u https://gitcode.com/openharmony/manifest.git \
        -b OpenHarmony-7.0-Release \
        -m chipsets/dayu200.xml \
        --no-repo-verify --depth=1
      repo sync -c -j8 --fail-fast
      repo forall -c 'git lfs pull'

      ohos --prepare standard
      ohos standard . ./build/prebuilts_download.sh
      ohos standard . \
        ./build.sh --product-name rk3568 --ccache -j16

    Images are written to out/rk3568/packages/phone/images/.

    Flash the resulting images to a physical Dayu200 from Linux:

      dayu200-flash -q
      dayu200-flash -a \
        -i "$HOME/src/openharmony-7.0/out/rk3568/packages/phone/images"

    To enter Loader/Maskrom mode, connect the USB OTG port, hold
    VOL+/RECOVERY, press and release RESET, wait about three seconds, then
    release VOL+/RECOVERY. `lsusb` should show Rockchip USB ID 2207:350a.
    Serial console settings are normally /dev/ttyUSB0 at 1500000 baud.
  */
  environment.systemPackages = [
    pkgs.git-repo
    pkgs.minicom
    pkgs.python3
    pkgs.usbutils
    pkgs.hihope-iot
    pkgs.ohos-build-env
  ];

  # Installs the packaged Rockchip Loader/Maskrom rules. Like extraRules,
  # services.udev.packages is merged with contributions from other modules.
  services.udev.packages = [ pkgs.hihope-iot ];
}
