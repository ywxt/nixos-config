# ywxt NixOS configuration

This is the Flake-based NixOS configuration stored at `~/nixos-config`. It
targets two hosts that share a common desktop and user configuration while
retaining host-specific hardware and development modules:

- `ywxt-ws`: personal desktop on AMD hardware
- `ywxt-work`: work machine with an Intel i7-12700 and UHD Graphics 770

User-level configuration is managed with hjem instead of Home Manager.

## Screenshot

![Niri and Noctalia desktop](docs/screenshots/desktop.png)

## Included

- NixOS unstable pinned by `flake.lock`
- Two hosts, `ywxt-ws` and `ywxt-work`, registered as
  `nixosConfigurations.ywxt-ws` and `nixosConfigurations.ywxt-work`
- Shared Nix settings (CERNET mirror, Noctalia Cachix and seven-day GC) in
  `modules/nix-settings.nix`
- hjem using the same nixpkgs instance
- Niri with a 4K `DP-1` layout on `ywxt-ws` and shared keybindings/rules
- Noctalia from its official Flake with a validated hjem-managed configuration
- TTY login startup through Fish, UWSM and hjem
- Noctalia-native lock, idle and screen-off handling (no swayidle)
- Noctalia-native brightness handling (no explicit brightnessctl package)
- Clash Verge Rev via `programs.clash-verge` with `pkgs.clash-verge-rev`,
  including autostart and TUN service mode
- PipeWire, NetworkManager, Bluetooth and Wayland portals
- hjem-managed Fcitx5 with the pinned `ywxt/rime-huma` scheme,
  librime-lua support and Fluent light/dark themes
- Thunar with archive integration, removable-media support, GVfs, UDisks2 and
  thumbnail generation
- Declarative MIME associations matching the current Firefox, imv, VLC, Ark,
  VS Code, Thunar, Steam and Telegram defaults
- GTK, Qtct and Kvantum configuration with Noctalia-generated dynamic colors
- GNOME Keyring, Polkit and Git OAuth credential support
- AMD graphics/Vulkan, Steam, Gamescope and MangoHud on `ywxt-ws`
- Intel UHD 770 graphics on `ywxt-work` through `modules/hardware-intel.nix`:
  Vulkan, VAAPI (`intel-media-driver`) and QSV (`vpl-gpu-rt`), thermald,
  `kvm-intel` and Intel microcode
- Java, Python, C/C++, Nix and Typst development tools managed through hjem
- A headless, container-isolated UniVPN SOCKS proxy and encrypted SSH target on
  `ywxt-work`; Clash Verge routing is not modified

Git, Git LFS, user Git settings and the OAuth credential helper are managed by
hjem for `ywxt`. Docker is enabled on both hosts by the shared development
module; Docker group membership grants root-equivalent privileges.

## Desktop and server user configuration

The hjem configuration has a shared command-line entry point and a desktop
add-on. In `flake.nix`, select the imports for each host explicitly:

```nix
# Server
hjem.users.ywxt.imports = [
  ./home/ywxt
];

# Desktop (ywxt-ws and ywxt-work)
hjem.users.ywxt.imports = [
  ./home/ywxt
  ./home/ywxt/desktop.nix
];
```

These are alternative examples. Both require `hjem.nixosModules.default` and
`hjem.users.ywxt.enable = true`; desktop configurations also pass `inputs`
through `hjem.specialArgs`, as the existing hosts do. The NixOS host remains
responsible for creating the user, enabling Fish and selecting system services.
The shared hjem entry point does not require desktop inputs or monitor options.

The shared configuration includes Fish, Starship, direnv, Git/LFS, Neovim,
command-line utilities and archive tools, **plus all existing command-line
development tools**, including C/C++ compilers, JDK, Python, Nix tools and Typst.
It sets the XDG base directories and `EDITOR=nvim`.

The desktop add-on supplies GUI applications, Niri/Noctalia, GTK/Qt themes,
input-method configuration, Kitty, Thunar, MIME associations and MangoHud. It
also adds desktop environment variables, Kitty shell integration and UWSM login
startup. Shared environment variables and PATH setup load before desktop startup.

The GTK and Tela Circle icon themes are installed for desktop users. After the
first desktop login, open `nwg-look`, select `adw-gtk3` as the GTK theme and
`Tela-circle` as the icon theme, then click **Apply** to update GSettings. Do not
use its **Export** action: the GTK 3 and GTK 4 `settings.ini` files are generated
declaratively and contain the same theme choices.

Git identity, LFS and the 30-day in-memory credential cache are shared. Servers
use `oauth -device` to authorize on another device; desktops retain the browser
OAuth helper. The main Git configuration includes a separately managed
`git/credentials.conf`, so each profile has exactly one OAuth helper. Upstream
device authorization currently supports GitHub and GitLab; use SSH or separately
configured HTTPS credentials for other platforms. See the
[git-credential-oauth documentation](https://github.com/hickford/git-credential-oauth#browserless-systems).

This split prepares the user configuration for a server; it does not register a
server host or change system-level desktop, networking or boot modules.

## Destructive clean installation

The following applies to `ywxt-ws` and erases `/dev/nvme0n1` completely. Confirm the device name from the
NixOS installer with `lsblk` before running anything. Boot the installer in UEFI
mode and put a copy of this Flake somewhere that will survive erasing the target
disk, such as a second USB drive, another disk or a remote Git repository.

From the live installer's normal shell, first copy or clone the configuration to
the installer's RAM-backed `/tmp`. For example:

```bash
cp -a /path/on/another-device/nixos-config /tmp/nixos-config
# Alternatively: git clone <repository-url> /tmp/nixos-config
test -f /tmp/nixos-config/flake.nix
```

Then become root, verify UEFI mode and inspect the target disk. Stop if the UEFI
check fails or `/dev/nvme0n1` is not the intended disk.

```bash
sudo -i
test -d /sys/firmware/efi/efivars
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS /dev/nvme0n1

wipefs -a /dev/nvme0n1
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1025MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 1025MiB 100%
partprobe /dev/nvme0n1
udevadm settle

mkfs.fat -F 32 -n boot /dev/nvme0n1p1
mkfs.btrfs -f -L nixos /dev/nvme0n1p2

mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
umount /mnt

mount -o subvol=@,compress=zstd:3,noatime,discard=async \
  /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/{boot,home,nix}
mount -o subvol=@home,compress=zstd:3,noatime,discard=async \
  /dev/disk/by-label/nixos /mnt/home
mount -o subvol=@nix,compress=zstd:3,noatime,discard=async \
  /dev/disk/by-label/nixos /mnt/nix
mount -o fmask=0077,dmask=0077 /dev/disk/by-label/boot /mnt/boot
```

Verify that every target filesystem is mounted at the location expected by
`hosts/ywxt-ws/hardware-configuration.nix`:

```bash
findmnt -R /mnt
lsblk -f /dev/nvme0n1
```

Install directly from the RAM-backed configuration. It is used only to build the
initial system and is intentionally not copied to `/etc/nixos`.

```bash
nix --extra-experimental-features 'nix-command flakes' flake check path:/tmp/nixos-config
nixos-install --flake /tmp/nixos-config#ywxt-ws
nixos-enter --root /mnt -c 'passwd ywxt'
reboot
```

After rebooting, log in as `ywxt` and clone the configuration repository to its
permanent maintenance location:

```bash
git clone <repository-url> "$HOME/nixos-config"
nix flake check "path:$HOME/nixos-config"
sudo nixos-rebuild switch --flake "$HOME/nixos-config#$(hostname)"
```

Replace `<repository-url>` with the actual Git URL before following these
instructions. The initial installation and the cloned repository should point at
the same revision to avoid an unexpected change during the first rebuild.

The hostname-specific output remains selectable dynamically with `hostname` on
each machine, or explicitly with `nixos-rebuild ... #ywxt-ws` and
`#ywxt-work`. Both hosts expect the same disk layout: a btrfs disk labelled
`nixos` with the `@`, `@home` and `@nix` subvolumes and an ESP labelled
`boot`. The partitioning commands above deliberately hard-code the `ywxt-ws`
target device; before installing `ywxt-work`, substitute its verified device
path and compare the mount points with
`hosts/ywxt-work/hardware-configuration.nix`. When adding new files, remember
that Git-based Flake references ignore untracked files. An explicit
`path:$HOME/nixos-config` URL can be used while testing untracked changes.

## Project templates

The Flake exposes reusable development environments for Rust, frontend,
Python and C/C++ projects. Initialize one in an empty project directory with:

```bash
nfi rust
nfi frontend
nfi python
nfi cpp
```

`nfi` is a Fish helper for
`nix flake init -t path:$HOME/nixos-config#<template>` and defaults to the Rust
template when called without an argument. If direnv is enabled, run
`direnv allow` after initialization; otherwise enter with `nix develop`. The
Rust template installs the selected `RUSTC_VERSION` through rustup only when
the compiler or Cargo is missing.

## Maintenance

```bash
nix flake check "$HOME/nixos-config"
nix flake update --flake "$HOME/nixos-config"
sudo nixos-rebuild switch --flake "$HOME/nixos-config#$(hostname)"
```

The `update` and `rebuild` aliases update `flake.lock` and rebuild the current
machine.

## OpenHarmony development

The OpenHarmony environment is imported only by `ywxt-work` through
`modules/ohos.nix`. It includes:

- `ohos`: Docker environments for standard, small and mini
  device-system source development and builds
- `hdc`: a directly executable host tool packaged from the OpenHarmony
  7.0 SDK, with its udev rule
- `git-repo` for the upstream multi-repository source tree; the shared hjem Git
  configuration supplies Git LFS
- `dayu200-flash`: HiHope's Linux x86_64 RK3568 flashing utility with packaged
  Loader/Maskrom udev rules

### HDC

`hdc` runs directly on the host through NixOS `nix-ld`; entering an SDK or FHS
shell is not required:

```bash
hdc list targets
```

### Dayu200/RK3568 source development

Acquire the OpenHarmony 7.0 source tree using its Dayu200 manifest:

```bash
mkdir -p "$HOME/src/openharmony-7.0"
cd "$HOME/src/openharmony-7.0"
repo init -u https://gitcode.com/openharmony/manifest.git \
  -b OpenHarmony-7.0-Release \
  -m chipsets/dayu200.xml \
  --no-repo-verify --depth=1
repo sync -c -j8 --fail-fast
repo forall -c 'git lfs pull'
```

The source tree remains on the host for editing. Enter its interactive build
environment with:

```bash
ohos standard "$HOME/src/openharmony-7.0"
```

The standard environment derives from OpenHarmony's official
`docker_oh_standard:3.2` image and adds autotools, CMake and Python venv support
needed by the pinned 7.0 source. It is built automatically on first use, or can
be prepared explicitly:

```bash
ohos --prepare standard
```

Download the prebuilts and create the complete RK3568 system images:

```bash
cd "$HOME/src/openharmony-7.0"
ohos standard . ./build/prebuilts_download.sh
ohos standard . \
  ./build.sh --product-name rk3568 --ccache -j16
```

The images are written to `out/rk3568/packages/phone/images/`.
`ohos` runs the container with the invoking user's UID and GID, so
new files in the bind-mounted checkout remain editable and removable by that
user. Its persistent container HOME is stored under
`$XDG_CACHE_HOME/ohos-build-env`, or `~/.cache/ohos-build-env` when
`XDG_CACHE_HOME` is unset. The same directory also holds the temporary
prebuilts download cache required beside the container source mount. Docker
access itself remains root-equivalent.

To pass one USB device through for tools such as `hdc`, identify its bus and
device numbers with `lsusb`, then set `OHOS_USB_DEVICE` when starting the
container:

```bash
OHOS_USB_DEVICE=/dev/bus/usb/001/007 ohos standard .
```

Only the selected character device is exposed. Its `BBB/DDD` path can change
after reconnecting the USB cable, so check `lsusb` again when necessary.
The container also uses Docker host networking, allowing build and test tools
to reach host services, RNDIS interfaces, and devices on host-accessible LANs.

Clear the persistent container home and prebuilts download cache without
touching the source tree or build output:

```bash
ohos --clean-cache
```

Small and mini system environments continue to use their official 3.2 images:

```bash
ohos small . python3 build.py -p qemu_small_system_demo@ohemu
```

### Dayu200 flashing

Connect the board through its USB OTG port and place it in Loader or Maskrom
mode. Query its state before writing the complete image set:

```bash
dayu200-flash -q
dayu200-flash -a \
  -i "$HOME/src/openharmony-7.0/out/rk3568/packages/phone/images"
```

The package grants the active local session access only to Rockchip USB devices
`2207:5000` and `2207:350a`. A serial console is normally available at
`/dev/ttyUSB0` with a baud rate of 1500000.

To update the packaged HDC, change `version`, `apiVersion`, the source URL and
hash in `pkgs/hdc.nix`. Releases are published under
<https://repo.huaweicloud.com/openharmony/os/>.

## UniVPN SSH access on ywxt-work

`ywxt-work` runs a headless Huawei UniVPN client in an isolated Docker network
namespace. A SOCKS5 listener is published only on `127.0.0.1:11080`; the host's
routes, DNS and Mihomo configuration are not changed. The listener is available
only while the VPN tunnel has an installed route.

Edit the encrypted settings with the offline recovery key:

```bash
SOPS_AGE_KEY_FILE=/safe/path/recovery-age-key.txt \
  sops secrets/ywxt-work-univpn.yaml
```

On `ywxt-work`, the SOPS system module installs a generic helper that uses the
host SSH key without exposing the recovery key or running the editor itself as
root. With no argument it lets you select a file from the repository's
`secrets` directory; a filename or path can also be supplied directly:

```bash
sops-secrets
sops-secrets ywxt-work-univpn.yaml
sops-secrets /path/to/secrets-directory
```

It expects the repository at `$HOME/nixos-config`. If it is elsewhere, set
`NIXOS_CONFIG_DIR` to its root before running the command.

The file is encrypted for the age recipient derived from the host SSH public
key. `SOPS_AGE_SSH_PRIVATE_KEY_FILE` is not suitable for this converted
recipient; the SSH private key must first be converted by `ssh-to-age` as shown
above.

Set `gateway`, `port`, `username`, `password` and `ssh-host` under `univpn`.
The VPN credentials and rendered Docker environment are root-only. `ssh-host`
is readable locally because the user-owned SSH client uses it for matching, but
all decrypted values exist only below `/run/secrets` on tmpfs.

After rebuilding, the UniVPN system module adds an `Include` to NixOS's
generated `/etc/ssh/ssh_config`, pointing at the runtime-only
`/run/secrets/rendered/univpn-ssh.conf`. It does not manage or overwrite the
user's `~/.ssh/config`. SOPS renders a normal `Host univpn-work` entry with the
decrypted `HostName` and a `netcat-openbsd` SSH `ProxyCommand`. Connections go
directly through the local UniVPN SOCKS proxy without changing Mihomo:

```bash
ssh univpn-work
```

Useful diagnostics:

```bash
systemctl status univpn-image docker-univpn
journalctl -u docker-univpn -f
ss -ltn 'sport = :11080'
ssh -G univpn-work | grep -E '^(user|proxycommand) '
curl --proxy socks5h://127.0.0.1:11080 https://example.com
```
