# UniVPN SSH access on ywxt-work

A headless Huawei UniVPN client runs in an isolated Docker network
namespace with a SOCKS5 listener on `127.0.0.1:11080`, available only
while the tunnel has an installed route. Host routes, DNS and Mihomo are
untouched.

Credentials live in `secrets/ywxt-work-univpn.yaml` (expected keys are
documented in `ywxt-work-univpn.template.yaml`); edit with
`sops-secrets` or the recovery key — see [secrets.md](secrets.md). Set
`gateway`, `port`, `username`, `password` and `ssh-host-1` under
`univpn`; the optional `ssh-host-2` renders a second host entry.
Decrypted values exist only under `/run/secrets` on tmpfs.

The module adds an `Include` to the generated `/etc/ssh/ssh_config`
pointing at the runtime-only `/run/secrets/rendered/univpn-ssh.conf`.
SOPS renders `Host univpn-work-1` / `univpn-work-2` entries with a
`netcat-openbsd` `ProxyCommand` through the SOCKS proxy:

```bash
ssh univpn-work-1
```

Diagnostics:

```bash
systemctl status univpn-image docker-univpn
journalctl -u docker-univpn -f
ss -ltn 'sport = :11080'
ssh -G univpn-work-1 | grep -E '^(user|proxycommand) '
curl --proxy socks5h://127.0.0.1:11080 https://example.com
```
