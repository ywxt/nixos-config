FROM docker.io/heywoodlh/microsocks@sha256:104e57a45b3bef71e8326fbfb8f27f3bbbc2ee2d15a22381990a593e8866163f AS microsocks

FROM docker.io/jesusdf/huawei-vpn@sha256:7306b742eb2ebafd4cdc03748bcb45a60b8c9095a121eef793e28431346de4c1

COPY --from=microsocks /usr/local/bin/microsocks /usr/local/bin/microsocks
COPY --from=microsocks /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY entrypoint.sh /usr/local/bin/univpn-proxy-entrypoint

RUN chmod 0755 /usr/local/bin/univpn-proxy-entrypoint

ENTRYPOINT ["/usr/local/bin/univpn-proxy-entrypoint"]
