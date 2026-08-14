# ywxt-ws NixOS configuration

This is the Flake-based NixOS configuration stored at `~/nixos-config`, with
Home Manager integrated as a NixOS module. It targets the current `ywxt-ws`
hardware and a clean installation on `/dev/nvme0n1`.

## Included

- Latest NixOS unstable pinned by `flake.lock`
- Home Manager using the same nixpkgs instance (`useGlobalPkgs = true`)
- Niri with the existing 4K `DP-1` layout and migrated keybindings/rules
- Noctalia v5 from its official Flake and Home Manager/NixOS modules
- TTY login startup through Fish, UWSM and Home Manager
- Noctalia-native lock, idle and screen-off handling (no swayidle)
- Noctalia-native brightness handling (no explicit brightnessctl package)
- FlClash from `pkgs.flclash`, including XDG autostart
- PipeWire, NetworkManager, Bluetooth and Wayland portals
- Home Manager-managed Fcitx5 with the pinned `ywxt/rime-huma` scheme,
  librime-lua support and Fluent light/dark themes
- Thunar with archive integration, removable-media support, GVfs, UDisks2 and
  thumbnail generation
- Declarative MIME associations matching the current Firefox, imv, VLC, Ark,
  VS Code, Thunar, Steam and Telegram defaults
- GTK, Qtct and Kvantum configuration with Noctalia-generated dynamic colors
- GNOME Keyring, Polkit and Git OAuth credential support
- AMD graphics/Vulkan, Steam, Gamescope and MangoHud
- Rust, Java and Python tools; no .NET, Node, Android or Flutter stack

Git and Git LFS are intentionally available at both the NixOS system level and
through Home Manager. User Git settings and the OAuth credential helper are
managed by Home Manager.

## Destructive clean installation

The following erases `/dev/nvme0n1` completely. Confirm the device name from the
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
nix flake check path:/tmp/nixos-config
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

The hostname-specific output remains `ywxt-ws`, while the maintenance alias
selects it dynamically with `hostname`. When adding new files, remember that
Git-based Flake references ignore untracked files. An explicit
`path:$HOME/nixos-config` URL can be used while testing untracked changes.

## Maintenance

```bash
sudo nixos-rebuild switch --flake "$HOME/nixos-config#$(hostname)"
nix flake update --flake "$HOME/nixos-config"
nix flake check "$HOME/nixos-config"
```

If FlClash system proxy works but TUN traffic does not, first test this narrowly
scoped fallback in `modules/networking.nix`:

```nix
networking.firewall.checkReversePath = "loose";
```

Do not disable the firewall pre-emptively.
