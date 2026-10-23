# Secrets management

- Each host owns an age keypair: private key at `/var/lib/sops-nix/key.txt`
  (root-only, persistent), public key anchored in `.sops.yaml` (`&ywxt_ws`,
  `&ywxt_work`).
- Secret files are encrypted to their host's key plus the offline
  `&recovery` key — `ywxt-work-opencode.yaml` additionally to `ywxt-ws` —
  so the recovery key alone can always decrypt everything.
- Private-key backups live in `secrets/host-keys/<hostname>.key`,
  encrypted to the recovery key only. The repository carries everything
  needed to reinstall a host except the recovery key itself.
- Host SSH keys are not used; rotating them does not affect secrets.
- The key file is not managed by NixOS — activation fails when it is
  missing, so restore it before the first rebuild of a fresh install.

## Editing

On a configured host (expects the repository at `$HOME/nixos-config`;
override with `NIXOS_CONFIG_DIR`):

```bash
sops-secrets                          # list and pick a file
sops-secrets ywxt-work-univpn.yaml    # edit a specific file
```

With the offline recovery key, on any machine:

```bash
SOPS_AGE_KEY_FILE=/safe/path/recovery-age-key.txt \
  sops secrets/ywxt-work-univpn.yaml
```

## Restoring a host key

Before the first activation of a fresh install, or whenever the key is
lost:

```bash
SOPS_AGE_KEY_FILE=/safe/path/recovery-age-key.txt \
  sops -d secrets/host-keys/<hostname>.key \
  | sudo install -Dm600 /dev/stdin /var/lib/sops-nix/key.txt
```

If the key is lost together with the machine: generate a replacement
with `age-keygen`, update the host's anchor in `.sops.yaml`, and
re-encrypt its secrets with `sops updatekeys` (recovery key).

## Adding a new host

1. `age-keygen -o /tmp/<hostname>.txt` — anchor the printed public key
   in `.sops.yaml` with a creation rule listing the new anchor and
   `*recovery`. The recovery-only rule for `secrets/host-keys/` already
   covers backups.

2. Back up the private key, encrypted to the recovery key only:

   ```bash
   install -m600 /tmp/<hostname>.txt secrets/host-keys/<hostname>.key
   sops -e -i secrets/host-keys/<hostname>.key && rm /tmp/<hostname>.txt
   ```

3. Create secrets with `sops secrets/<hostname>-<name>.yaml`. To grant
   the new host access to a shared file such as
   `secrets/ywxt-work-opencode.yaml`, add its anchor to that rule and
   run `sops updatekeys` with the recovery key.

4. Copy the closest host under `hosts/`, adjust hardware and module
   selection, register it in `flake.nix`, and restore the key backup
   before `nixos-install` (see [install.md](install.md)).
