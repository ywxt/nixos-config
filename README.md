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
- PipeWire, Fcitx5 + Rime, NetworkManager, Bluetooth and Wayland portals
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
NixOS installer with `lsblk` before running anything.

```bash
sudo -i
wipefs -a /dev/nvme0n1
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1025MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 1025MiB 100%

mkfs.fat -F 32 -n boot /dev/nvme0n1p1
mkfs.btrfs -f -L nixos /dev/nvme0n1p2

mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
umount /mnt

mount -o subvol=@,compress=zstd:3,noatime,discard=async \
  /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/{boot,home,nix,etc/nixos}
mount -o subvol=@home,compress=zstd:3,noatime,discard=async \
  /dev/disk/by-label/nixos /mnt/home
mount -o subvol=@nix,compress=zstd:3,noatime,discard=async \
  /dev/disk/by-label/nixos /mnt/nix
mount -o fmask=0077,dmask=0077 /dev/disk/by-label/boot /mnt/boot
```

Copy `~/nixos-config` to `/mnt/etc/nixos`, then install:

```bash
cp -a "$HOME/nixos-config/." /mnt/etc/nixos/
nixos-install --flake /mnt/etc/nixos#ywxt-ws
nixos-enter --root /mnt -c 'passwd ywxt'
reboot
```

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
