# Clean installation

Erases the target disk completely. Shown for `ywxt-ws` with
`/dev/nvme0n1`; substitute the verified device for `ywxt-work` and
compare mount points with its `hardware-configuration.nix`. Boot the
installer in UEFI mode, and keep a copy of the Flake on a medium that
survives the wipe.

Copy the configuration into the installer's RAM-backed `/tmp`:

```bash
cp -a /path/on/another-device/nixos-config /tmp/nixos-config
test -f /tmp/nixos-config/flake.nix
```

Partition and format — stop if the UEFI check fails or the device is
wrong:

```bash
sudo -i
test -d /sys/firmware/efi/efivars
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS /dev/nvme0n1

wipefs -a /dev/nvme0n1
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1025MiB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 1025MiB 100%
partprobe /dev/nvme0n1 && udevadm settle

mkfs.fat -F 32 -n boot /dev/nvme0n1p1
mkfs.btrfs -f -L nixos /dev/nvme0n1p2
```

Mount as expected by `hosts/<hostname>/hardware-configuration.nix`:

```bash
mount /dev/disk/by-label/nixos /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
umount /mnt

mount -o subvol=@,compress=zstd:3,noatime,discard=async /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/{boot,home,nix}
mount -o subvol=@home,compress=zstd:3,noatime,discard=async /dev/disk/by-label/nixos /mnt/home
mount -o subvol=@nix,compress=zstd:3,noatime,discard=async /dev/disk/by-label/nixos /mnt/nix
mount -o fmask=0077,dmask=0077 /dev/disk/by-label/boot /mnt/boot

findmnt -R /mnt && lsblk -f /dev/nvme0n1
```

Restore the SOPS age key (the installer does not ship `sops`):

```bash
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#sops
SOPS_AGE_KEY_FILE=/safe/path/recovery-age-key.txt \
  sops -d /tmp/nixos-config/secrets/host-keys/ywxt-ws.key \
  | install -Dm600 /dev/stdin /mnt/var/lib/sops-nix/key.txt
```

Install and set the user password. The RAM-backed copy is used only to
build the initial system and is intentionally not copied to `/etc/nixos`:

```bash
nix --extra-experimental-features 'nix-command flakes' flake check path:/tmp/nixos-config
nixos-install --flake /tmp/nixos-config#ywxt-ws
nixos-enter --root /mnt -c 'passwd ywxt'
reboot
```

After rebooting, clone the repository to `$HOME/nixos-config` and
rebuild from it. Keep the clone at the same revision as the installation
to avoid an unexpected first rebuild.

Notes:

- Host selection: `nixos-rebuild ... #ywxt-ws` / `#ywxt-work`, or
  `#(hostname)` dynamically.
- Git-based Flake references ignore untracked files; use an explicit
  `path:$HOME/nixos-config` URL while testing untracked changes.
