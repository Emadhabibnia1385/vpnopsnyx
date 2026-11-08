# BackPack Runbook

**Source:** https://github.com/AminMGMT/BackPack  
**Trust:** `verified-source`, `third-party`, `community`, `high-impact`

BackPack is a Go tunnel engine for Iran-to-origin deployments. Upstream documents
reverse tunnels, direct layer-3 tunnels, multiple TCP/UDP/WebSocket/ICMP carriers,
transport fallback, health checks, managed servers, monitoring, and backup/restore.

## Preflight

1. Record both servers, roles, routes, interfaces, ports, firewall rules, MTU, DNS,
   BackPack version, services, and an out-of-band management path.
2. Start with the Iran side for the documented reverse topology; confirm direction
   rather than assuming that product names imply client/server roles.
3. Treat security tokens, `backpack://` setup links, panel credentials, recovery
   codes, API tokens, TLS keys, Telegram settings, and backups as secrets.
4. Review the installer and pin a release when possible.

## Install Boundary

The upstream README currently documents this installer for both servers:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/AminMGMT/BackPack/main/install.sh)
```

It is remote code execution. Download and inspect it first. Upstream states that
release archives are selected by architecture and checked against published SHA-256
values; independently record the selected version and checksum.

## Configure And Verify

- Configure Iran before kharej for a reverse tunnel and use the same transport and token.
- Keep the tunnel port distinct from user-facing forwarded ports.
- Enable UDP forwarding only when the transported service requires it.
- Use the built-in Status, Health Check, Link Test, and tunnel metrics.
- Verify sockets and counters on both ends, then test the real application through
  every advertised TCP/UDP port. A connected control path alone is insufficient.
- For direct layer-3 mode, verify routes, source addresses, MTU, and management reachability.

## Fleet Standard: wsmux + accept_udp (field-observed)

For user-facing TCP services (Xray VLESS/Reality, Trojan, and similar) between an in-country
relay and a foreign exit, the profile below carried tens of thousands of concurrent user
connections per relay. Both ends must use the same `transport`, `token` and `accept_udp`.
The relay runs `[server]`; the exit dials it with `[client]`. Each `ports` entry is
`USER_PORT=TARGET`, and the target is dialed from the exit, so `127.0.0.1` means the exit's own
inbound.

Relay (`/etc/backpack/NAME.toml`):

```toml
[server]
bind_addr = "0.0.0.0:TUNNEL_PORT"
token = "<TOKEN>"                      # secret: generate per tunnel, never commit
transport = "wsmux"
accept_udp = true
ports = ["USER_PORT=127.0.0.1:USER_PORT"]
mss = 1350
preset = "aggressive"
channel_size = 8192
so_rcvbuf = 33554432
so_sndbuf = 33554432
nodelay = true
keepalive_period = 60
heartbeat = 25
log_level = "warn"
```

Exit (`/etc/backpack/relay-NAME.toml`):

```toml
[client]
remote_addr = "RELAY_IP:TUNNEL_PORT"
token = "<TOKEN>"
transport = "wsmux"
accept_udp = true
retry_interval = 2
mss = 1350
preset = "aggressive"
channel_size = 8192
so_rcvbuf = 33554432
so_sndbuf = 33554432
nodelay = true
keepalive_period = 60
heartbeat = 25
log_level = "warn"
```

### What `accept_udp` does and does not do

- With it on, the relay also listens on UDP for each forwarded port and carries those datagrams
  inside the tunnel. Without it only TCP crosses.
- It matters only when the exit service itself listens on UDP (WireGuard, Hysteria2,
  Shadowsocks-UDP). For VLESS/Reality users the application's UDP (QUIC, calls) rides inside the TCP
  stream, so the flag changes nothing for them.
- UDP inside a TCP-based carrier suffers head-of-line blocking. A low-rate real-time service
  (a game over WireGuard measured about 41 ms, 0% loss through `wsmux`) is fine; sustained high-rate
  UDP is not (about 24% loss at 50 Mbit/s offered).
- Cost when unused is negligible, but every forwarded port also becomes an open UDP listener on the
  relay. Turn it off where no UDP service exists if you want the smaller surface.

### Choosing the transport

- Judge a transport on the real data path, not on a single-stream benchmark. `wsmux` multiplexes many
  user streams onto few TCP connections; `stealth`, `tcp` and `ws` use about one connection per
  stream. Converting a busy relay's tunnel from `wsmux` to `stealth` raised its connections about 6x
  and its CPU, and was reverted.
- Use `stealth` only for one specific route where the WebSocket-framed transports connect but pass no
  data. Detect it with a data probe through the relay (any HTTP status means bytes flowed, `000`
  means they did not):

```bash
curl -sk -m 8 --resolve www.cloudflare.com:USER_PORT:RELAY_IP \
  -o /dev/null -w '%{http_code}\n' https://www.cloudflare.com:USER_PORT/
```

  Use the fallback SNI of the exit's inbound if it differs. This proves the listener and fallback
  path only; test a real client for authentication and bandwidth.

### Keep tunnels alive across reboots and provider events

Drop-in for both ends (`systemctl edit UNIT`), so a unit waits for the network and never gives up:

```ini
[Unit]
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=0
[Service]
Restart=always
RestartSec=3
```

- After a provider network event (DDoS filtering, route change) the control channel can reconnect
  while the data plane carries nothing. Restart both tunnel units for the affected location and
  re-run the data probe; do not restart unrelated locations.
- A reconnect storm after restarting every unit at once can spike a relay for a few minutes; restart
  one location at a time.

### Reserve the exit's inbound ports

An exit inbound whose port lies in the ephemeral range (default 32768-60999) can be taken by an
outbound socket while Xray is down, and the next start fails with `bind: address already in use`.
Reserve every inbound and node-API port (comma list, ranges allowed):

```bash
echo 'net.ipv4.ip_local_reserved_ports = USER_PORT1,USER_PORT2,NODE_API_PORT' > /etc/sysctl.d/99-reserved-ports.conf
sysctl -p /etc/sysctl.d/99-reserved-ports.conf
```

### Audit before removing anything

Run [`scripts/node/bpaudit.sh`](../../scripts/node/bpaudit.sh) on every host. It lists each BackPack
unit with its transport and `accept_udp`, and measures layer-3 (GRE/xDi) links by interface
byte-counter delta. Do not call a layer-3 link unused because it has no TCP sockets or does not answer
ping: a raw GRE carrier has no TCP sockets and the far end often drops ICMP. In one fleet a link that
looked dead by those two tests was carrying a partner's live traffic; removing it cut that partner
off until it was restored from the backup. Move unit and config files to a backup directory instead
of deleting them, and confirm real-user bytes on the exit first.

### Cost and quota notes

- Relay quotas are usually counted on egress only, so a relay's billed traffic is about the users'
  traffic once; retransmissions add roughly the packet-loss rate (about 1% observed).
- Do not run gigabit benchmarks through a relay that has a traffic quota: it burns the quota and can
  trip the provider's anti-DDoS, which cut the relay off from abroad for about half an hour in one
  case.

## Backup, Upgrade, And Rollback

Create and checksum a backup before changes; protect it because upstream backups may
contain tunnel configuration, panel settings, credentials, Telegram settings, TLS
material, and scheduled tasks. Preserve the previous binary, configuration, systemd
units, routes, and firewall state. On failure, stop new units, restore the recorded
state and prior release, reload systemd, and retest the original data path.
