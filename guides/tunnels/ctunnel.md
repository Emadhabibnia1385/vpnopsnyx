# C-Tunnel Runbook

**Source:** https://github.com/CIAUB/C-Tunnel
**Author / contact:** CIAUB — Telegram channel t.me/CiAUB_CH
**Status:** `verified-source`, `third-party`, `community`, `high-impact`
**License:** AGPL-3.0 (its Manage menu is derived from BackPack by Amin Mohammadi / AminMGMT).
Latest reviewed release: **v0.2.1**.

High-performance direct **and** reverse tunneling engine with **28 transport
methods** across kernel L3, kernel L2, and an "UDP-Crypt" family, plus FRP-style
reverse modes. Written in Go, one binary plus a kernel helper, a terminal menu
(BackPack-style), one-line `ctunnel://` setup links, a built-in connection tester,
and an optional web panel. Positioned for Iran↔Kharej links: you forward real
service ports over an obfuscated/encrypted carrier and run your real end-to-end
protocol (VLESS+Reality, WireGuard, …) through it.

## What it provides

- **L3-Direct (13):** `gre`, `ipip`, `6to4`, `6to4-gre`, `sit`, `ip6gre`, `ipip6`,
  `ip6ip6`, `wireguard` (kernel ChaCha20-Poly1305), `xfrm-ipsec` (GRE + kernel IPsec
  ESP AES-GCM-256), `fou-gre`, `gue-ipip`, `ecmp-lanes` (2–8 parallel keyed GRE).
- **L2-Direct (7):** `eoip` (MikroTik-compatible), `gretap`, `ip6gretap`, `vxlan`,
  `geneve`, `l2tpv3`, `etherip`.
- **UDP-Crypt (8):** `dtls-1.3`, `quic-v1`, `srtp-direct`, `wg-stealth`
  (random-magic header + junk burst), `rudp-fec` (XOR-FEC 2+1 parity, for lossy
  links), `dnscrypt-udp`, `ntp-direct`, `openvpn-dco`. Each wraps packets as
  AES-256-GCM to resemble that protocol — **they are not full implementations**.
- **Reverse modes:** `rev+` (UDP-Crypt / WireGuard where Kharej dials Iran) and
  `frp+` (kernel L3/L2 carried over up to 8 parallel TCP streams shaped to look like
  TLS records). FRP-style reverse is the pattern to reach for when the carrier must
  cross a boundary that drops inbound or international UDP.
- **Crypto / integrity:** AES-256-GCM, a separate key per direction, a 2000-packet
  anti-replay window, random padding. UDP-Crypt sequence numbers are **clock-based**,
  so both servers need roughly correct time (NTP).
- **Tooling:** `ctunnel conntest-server` / `ctunnel conntest` report which of the 28
  methods actually pass between the two servers, their speed, and a recommendation —
  run this before choosing a method. Also `linktest`/`speedtest-server`, `optimize`
  (BBR, fq, buffers, ip_forward), a SOCKS5/HTTP `proxy-serve`, and a web panel.

## Topology & config

- Run the installer on **both** servers. Create a tunnel in the menu (or from a
  `ctunnel://` link), pick a method and a per-tunnel `10.77.N.0/30` subnet, and add
  port-forwards. Forward syntax: `443` (same port) or `2053=8443` (listen 2053 →
  forward 8443). UDP-Crypt / WireGuard / VXLAN/Geneve run over UDP, so their carrier
  UDP port must be open; FRP-style reverse needs only the TCP stream port.
- Paths: `/etc/ctunnel/state.json` (tunnels, panel port, login code),
  `/etc/ctunnel/panel.json` (panel base path, domain, cert paths),
  `/etc/ctunnel/tunnels/<name>.env` (one tunnel's settings),
  `/usr/local/lib/ctunnel/ctunnel-kernel` (interfaces, port-forwards, IPsec).
- Services: `ctunnel@<name>.service` (kernel tunnels),
  `ctunnel-engine@<name>.service` (UDP-Crypt, EoIP, EtherIP),
  `ctunnel-panel.service` (web panel). Logs:
  `journalctl -u ctunnel@<name> -u ctunnel-engine@<name> -n 50`.

## Install (review before running — treat as remote code execution)

Documented one-liner, run as **root** with systemd on both servers (amd64/arm64,
Ubuntu 20.04+/Debian 11+). **Pin the reviewed version** rather than tracking latest:

```bash
sudo bash -c "$(curl -sL https://raw.githubusercontent.com/CIAUB/C-Tunnel/main/install.sh)" v0.2.1
```

(`CTUNNEL_VERSION=v0.2.1` also works; an explicit argument wins.) The installer
downloads the release assets, verifies each against the release `SHA256SUMS`, and
installs nothing if any hash fails. Build-from-source path: `git clone`, `go test
./...`, `sudo bash install.sh`.

**Security review flags (do not ignore):**
- Tracks the `main` installer by default — **pin a release/commit** for production.
- The checksum file ships from the same release as the binaries, so it is integrity,
  not independent provenance. Verify the release yourself where it matters.
- The web panel defaults to **HTTP** on a random persisted path; five wrong login
  codes block an IP for five minutes; HTTPS only when a valid cert/key is configured.
  Keep the panel off the public internet or terminate TLS in front of it.
- Services run as **root** (kernel tunnels, `setcap`-style net admin, IPsec). Blast
  radius is high; review `ctunnel@.service` / `ctunnel-engine@.service` before enabling.
- No formal external audit is published (repo links an `AUDIT_FA.md`; read it first).
- Clock dependence: a wrong system clock silently breaks UDP-Crypt — confirm NTP.

## Operate safely

1. Record both sides: method, `ctunnel://` link (**secret — contains keys, never
   print/commit**), port-forwards, chosen subnet, firewall rules, MTU, and the
   last known-good `/etc/ctunnel/tunnels/<name>.env`.
2. Run `ctunnel conntest-server` on one side and `ctunnel conntest 'ctunnel-test://…'`
   on the other **first** — let it tell you which methods pass and how fast, rather
   than guessing. On Iran↔Kharej links expect native/international UDP methods
   (`quic-v1`, plain `wireguard`) to be dropped and TCP-stream `frp+` / some UDP-Crypt
   methods (`rudp-fec`, `wg-stealth`) to survive — verify per path.
3. Bring the Kharej side up first, then Iran; confirm with `ctunnel status` and
   inspect sockets/logs.
4. **Verify a real application request through every forwarded port**, and confirm
   reconnect after a controlled `ctunnel restart <name>`.
5. Treat the path as unproven for 24h (filtered paths can die within the hour) —
   re-check tunnel health and real-user bytes the next day.

**Rollback:** `ctunnel down <name>` (and `systemctl disable --now
ctunnel@<name> ctunnel-engine@<name>`), restore the prior `<name>.env` and firewall
rules, `ctunnel restart <name>` or remove the tunnel from the menu. Full removal:
`install.sh --uninstall`.

> All vendor performance claims ("25+ methods", speed figures) are the author's own
> and are **unverified**. Inclusion here is discovery, not endorsement.
