# ywxt NixOS configuration

This is the Flake-based NixOS configuration stored at `~/nixos-config`. It
targets two hosts sharing the same module set:

- `ywxt-ws`: personal desktop on AMD hardware with a clean installation on
  `/dev/nvme0n1`
- `ywxt-work`: work machine for OpenHarmony/HarmonyOS development on an
  Intel i7-12700 with UHD Graphics 770 integrated graphics and a 1TB disk

User-level configuration is managed with hjem instead of Home Manager.

## Included

- Latest NixOS unstable pinned by `flake.lock`
- Two hosts, `ywxt-ws` and `ywxt-work`, registered as
  `nixosConfigurations.ywxt-ws` and `nixosConfigurations.ywxt-work`
- Shared Nix settings (CERNET mirror, noctalia cachix, GC) in
  `modules/nix-settings.nix`
- hjem using the same nixpkgs instance
- Niri with the existing 4K `DP-1` layout and migrated keybindings/rules
- Noctalia v5 from its official Flake and hjem/NixOS modules
- TTY login startup through Fish, UWSM and hjem
- Noctalia-native lock, idle and screen-off handling (no swayidle)
- Noctalia-native brightness handling (no explicit brightnessctl package)
- FlClash from `pkgs.flclash`, including XDG autostart
- PipeWire, NetworkManager, Bluetooth and Wayland portals
- hjem-managed Fcitx5 with the pinned `ywxt/rime-huma` scheme,
  librime-lua support and Fluent light/dark themes
- Thunar with archive integration, removable-media support, GVfs, UDisks2 and
  thumbnail generation
- Declarative MIME associations matching the current Firefox, imv, VLC, Ark,
  VS Code, Thunar, Steam and Telegram defaults
- GTK, Qtct and Kvantum configuration with Noctalia-generated dynamic colors
- GNOME Keyring, Polkit and Git OAuth credential support
- AMD graphics/Vulkan, Steam, Gamescope and MangoHud
- Intel UHD 770 graphics on `ywxt-work` through `modules/hardware-intel.nix`:
  Vulkan, VAAPI (`intel-media-driver`) and QSV (`vpl-gpu-rt`), thermald,
  `kvm-intel` and Intel microcode
- Rust, Java and Python tools; no .NET or Android stack
- `ohos-sdk` from `pkgs/ohos-sdk.nix`: OpenHarmony SDK 26.0.0.38 (API 26,
  from the `7.0-Release` image) for Linux x86_64, packaged with
  `buildFHSEnv` and installed through `modules/ohos-sdk.nix`

The `ohos-sdk` package keeps the unwrapped SDK under
`$(nix-build ...)/opt/ohos-sdk/26` (also available as
`pkgs.ohos-sdk.passthru.sdk`) and provides the `ohos-sdk` command, which
starts an FHS-compatible shell with `OHOS_SDK_HOME`, `OHOS_NDK_HOME` and
`PATH` (`native/llvm/bin`, `toolchains`) already set up. Inside, OHOS clang,
`hdc` and friends run directly:

```bash
ohos-sdk
clang --target=aarch64-linux-ohos --sysroot=$OHOS_NDK_HOME/sysroot hello.c -o hello
hdc list targets
```

Only the `ohos-sdk/linux` components of the upstream bundle are installed; the
`windows/` and `ohos/` parts are dropped, matching the packaging of the
`ohos-sdk` AUR package.

Git and Git LFS are intentionally available at both the NixOS system level and
through hjem. User Git settings and the OAuth credential helper are managed by
hjem.

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
`boot`, so the installation procedure above applies to `ywxt-work` on its 1TB
disk as well; verify the mount points against
`hosts/ywxt-work/hardware-configuration.nix` before installing. When adding
new files, remember that Git-based Flake references ignore untracked files. An
explicit `path:$HOME/nixos-config` URL can be used while testing untracked
changes.

## Maintenance

```bash
sudo nixos-rebuild switch --flake "$HOME/nixos-config#$(hostname)"
nix flake update --flake "$HOME/nixos-config"
nix flake check "$HOME/nixos-config"
```

To update the OpenHarmony SDK, bump `version`/`apiVersion` and the pinned
`hash` in `pkgs/ohos-sdk.nix` to a newer release from
`https://repo.huaweicloud.com/openharmony/os/`.

If FlClash system proxy works but TUN traffic does not, first test this narrowly
scoped fallback in `modules/networking.nix`:

```nix
networking.firewall.checkReversePath = "loose";
```

Do not disable the firewall pre-emptively.
