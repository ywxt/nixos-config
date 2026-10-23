# OpenHarmony development

`ywxt-work` only, via `modules/ohos.nix`:

- `ohos` — Docker build environments for standard, small and mini
  device systems
- `hdc` — host tool from the OpenHarmony 7.0 SDK, runs directly through
  `nix-ld`, with its udev rule
- `git-repo` — upstream multi-repository source; Git LFS comes from the
  shared hjem Git configuration
- `dayu200-flash` — RK3568 flashing utility with Loader/Maskrom udev
  rules

## Dayu200/RK3568 source build

Acquire the OpenHarmony 7.0 source tree:

```bash
mkdir -p "$HOME/src/openharmony-7.0" && cd "$HOME/src/openharmony-7.0"
repo init -u https://gitcode.com/openharmony/manifest.git \
  -b OpenHarmony-7.0-Release -m chipsets/dayu200.xml --no-repo-verify --depth=1
repo sync -c -j8 --fail-fast
repo forall -c 'git lfs pull'
```

Enter the build environment — the official `docker_oh_standard:3.2`
image plus autotools, CMake and Python venv support. It is built on
first use, or explicitly with `ohos --prepare standard`:

```bash
ohos standard "$HOME/src/openharmony-7.0"
```

Download prebuilts and build. Images land in
`out/rk3568/packages/phone/images/`:

```bash
ohos standard . ./build/prebuilts_download.sh
ohos standard . ./build.sh --product-name rk3568 --ccache -j16
```

Container notes:

- Runs with the invoking user's UID/GID, so files in the bind-mounted
  checkout stay user-owned.
- Persistent container HOME and prebuilts cache live under
  `$XDG_CACHE_HOME/ohos-build-env` (default `~/.cache/ohos-build-env`);
  clear both with `ohos --clean-cache` without touching the source tree.
- Docker host networking, so build and test tools can reach host
  services, RNDIS interfaces and LAN devices.
- USB passthrough for tools such as `hdc`: set
  `OHOS_USB_DEVICE=/dev/bus/usb/BBB/DDD` (recheck with `lsusb` after
  reconnecting); only that device is exposed.
- Small and mini systems use their official 3.2 images:
  `ohos small . python3 build.py -p qemu_small_system_demo@ohemu`

## Dayu200 flashing

Put the board in Loader or Maskrom mode through its USB OTG port, then:

```bash
dayu200-flash -q
dayu200-flash -a -i "$HOME/src/openharmony-7.0/out/rk3568/packages/phone/images"
```

Udev grants the local session access to Rockchip `2207:5000` and
`2207:350a` only. Serial console: `/dev/ttyUSB0` at 1500000 baud.

Updating the packaged HDC: change `version`, `apiVersion`, the source
URL and hash in `pkgs/hdc.nix`; releases are published at
<https://repo.huaweicloud.com/openharmony/os/>.
