#!/bin/sh
set -eu

tun_device="${TUN_DEVICE:-cnem_vnic}"
proxy_dns="${PROXY_DNS:-1.1.1.1}"
vpn_pid=
proxy_pid=

stop_proxy() {
  if [ -n "$proxy_pid" ] && kill -0 "$proxy_pid" 2>/dev/null; then
    kill "$proxy_pid"
    wait "$proxy_pid" 2>/dev/null || true
  fi
  proxy_pid=
}

cleanup() {
  stop_proxy
  if [ -n "$vpn_pid" ] && kill -0 "$vpn_pid" 2>/dev/null; then
    kill "$vpn_pid"
    wait "$vpn_pid" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

# The vendor CLI echoes the login name, so do not forward its output to the
# host journal. Docker health status remains available for diagnostics.
/entrypoint.sh >/dev/null 2>&1 &
vpn_pid=$!

while kill -0 "$vpn_pid" 2>/dev/null; do
  if ip route show dev "$tun_device" | grep -q .; then
    if ! grep -qx "nameserver $proxy_dns" /etc/resolv.conf; then
      printf 'nameserver %s\n' "$proxy_dns" > /etc/resolv.conf
    fi
    if [ -z "$proxy_pid" ] || ! kill -0 "$proxy_pid" 2>/dev/null; then
      microsocks -i 0.0.0.0 -p 1080 &
      proxy_pid=$!
      echo "UniVPN tunnel ready; SOCKS5 proxy enabled"
    fi
  else
    if [ -n "$proxy_pid" ]; then
      echo "UniVPN tunnel unavailable; SOCKS5 proxy disabled"
    fi
    stop_proxy
  fi
  sleep 2
done

wait "$vpn_pid"
