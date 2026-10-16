<p align="center">
  <img src="./assets/readme/hero.png" width="100%" alt="VPNOpsNyx in an agent session: a relay-by-exit data-path matrix measured in delivered bytes, panel health for two brands, and a DNS change waiting for the operator's approval">
</p>

<h1 align="center">VPNOpsNyx</h1>

<p align="center">
  The operator skill that lets Claude, Codex and other AI agents run a VPN fleet:<br>
  panels, nodes, tunnels, relays and DNS, checked with real bytes and changed only with your OK.
</p>

<p align="center">
  <a href="https://github.com/nyxon-tech/vpnopsnyx/actions/workflows/quality.yml"><img src="https://img.shields.io/github/actions/workflow/status/nyxon-tech/vpnopsnyx/quality.yml?branch=main&style=flat-square&color=a8b2ff&labelColor=303345&label=checks" alt="Checks"></a>
  <img src="https://img.shields.io/badge/version-0.6.0-a8b2ff?style=flat-square&labelColor=303345" alt="Version 0.6.0">
  <img src="https://img.shields.io/badge/Claude%20%C2%B7%20Codex%20%C2%B7%20any%20agent-a8b2ff?style=flat-square&labelColor=303345" alt="Claude, Codex and any agent">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-a8b2ff?style=flat-square&labelColor=303345" alt="MIT license"></a>
</p>

<p align="center">
  <b>English</b> · <a href="README.fa.md">فارسی</a> · <a href="README.ru.md">Русский</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

A VPN fleet breaks in ways a status page never shows. A relay answers `200` and then stalls after 15 KB. A tunnel pings fine and carries nothing. A datacenter rotates your IP and every mode that worked yesterday is gone. An exit gets throttled to 200 Mbit and nobody notices until users complain.

**VPNOpsNyx** gives your AI agent the playbook an experienced operator carries in their head. The agent inspects the fleet, measures every relay-to-exit path with delivered bytes from in-country probes, finds the cause, proposes a fix with its rollback, and waits for you before it touches DNS, a panel or a tunnel. It is not a VPN, a tunnel or a panel fork: it is Markdown, JSON and small shell scripts that any agent can load.

## Install

**Claude Code**

```sh
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.claude/skills/vpnopsnyx
```

**Codex**

```sh
git clone https://github.com/nyxon-tech/vpnopsnyx ~/.codex/skills/vpnopsnyx
```

**Any other agent:** clone it into the agent's skill or plugin folder and point it at [`SKILL.md`](SKILL.md). Everything else is plain Markdown and JSON, so any runtime can read it. See [docs/agent-compatibility.md](docs/agent-compatibility.md).

Then just ask, in any language:

```text
check every server, both brands
the panel won't load from Iran, find out why
move Germany to my new Hetzner server
pull the relay that keeps dropping out of DNS
write a ticket for the datacenter about the packet loss
```

## What it knows

| | |
| --- | --- |
| **Panels** | PasarGuard, 3x-ui / Sanaei, Marzban, Marzneshin, Hiddify, Remnawave, S-UI: nodes, certificates, upgrades, database pools, login blocking. |
| **Cores** | Xray-core, sing-box, WireGuard, AmneziaWG, Hysteria2, TUIC, VLESS / VMess / Trojan, Shadowsocks, Reality and TLS. |
| **Tunnels** | GRE, [BackPack](https://github.com/AminMGMT/BackPack) xDi (forward and reverse), Backhaul, Rathole, Paqet, FRP, DaggerConnect, SIT / 6to4, WireGuard relays. |
| **Relays** | nftables DNAT with dry-run and rollback, real users per relay, MSS clamping, quota and capacity, brand separation. |
| **DNS** | Cloudflare records per location and per brand, failover and restore, a log of every change. |
| **Iran filtering** | Bulk throttling, inbound-from-abroad blackholes, per-datacenter GRE, IP blacklists, quota exhaustion that looks like an outage. |
| **Operations** | Health snapshots, data-path matrices, migrations, safe upgrades and reboots, incident triage, provider tickets. |

## How it works

<p align="center">
  <img src="./assets/readme/how-it-works.svg" width="100%" alt="Users reach an Iranian relay through a DNS name, the relay forwards to a foreign exit over a tunnel, and the exit is managed by a panel. VPNOpsNyx measures each layer and changes nothing without the operator's approval">
</p>

- **Measure bytes, not status codes.** Every path is tested by how much data actually arrives (a full test page, not just `HTTP 200`), from probes in a different datacenter. A relay testing itself proves nothing.
- **Two probes before any DNS change.** One vantage point can be broken on its own. The skill only steers users after two in-country probes agree.
- **Test on a spare port, then switch.** New tunnels are built and measured beside the live one; the live port moves only after the new path passes, and the old one stays up for rollback.
- **Read-only until you approve.** The agent never prints or stores credentials, keys, tunnel tokens or subscription links, and records how to undo every change it makes.

<details>
<summary><b>Field lessons, October 2026</b></summary>

Sanitized, `operator-observed` lessons from a two-brand fleet with several Iranian relay datacenters:

1. **Persistent GRE relay links.** Plain GRE plus DNAT carried users where TCP DNAT and xDi failed, with almost no CPU and no per-exit link limit; some datacenters block it. `scripts/relay/greunit.sh`, `references/tunnels.md` §16.
2. **A relay that gets a new IP is a new relay.** On a rotated range GRE and bulk TCP died and only exit-dialed xDi worked, then that died too. Re-measure every mode and never let such a relay be a location's only one. `references/tunnels.md` §17.
3. **One dialed xDi link per exit, confirmed again.** A second dial passed its first test and died within minutes on four exits. Exits shared by two brands have one dial budget in total. `references/tunnels.md` §15.
4. **Keep xDi relays out of the panel and subscription domain.** Reads worked but `POST`/`PUT` bodies stalled ~16 minutes, so bot renewals failed. Test a `POST` through every address. `references/pasarguard.md` §16.
5. **Dead links still burn CPU.** Disable them on both ends as soon as they are confirmed dead.
6. **Watch failed panel logins and block deliberately.** `scripts/panel/auth_failures.sh`, `scripts/panel/blocklist.sh`, `references/pasarguard.md` §17.
7. **Audit brand separation on both DNS and relays.** `scripts/local/dns_brand_audit.sh` for records, `scripts/relay/forward_audit.sh` for forwarded ports.
8. **Test the subscription domain through every address, with a real download.** A direct panel IP passed logins but stalled 200 KB downloads from most in-country datacenters. `scripts/relay/panel_path_check.sh`, `references/pasarguard.md` §16.
9. **Never leave a DNS name empty.** Resolvers cache NXDOMAIN for up to 30 minutes. `references/cloudflare.md`.
10. **An inbound in no group reaches nobody.** `scripts/panel/inbound_groups.py`, and adding a tunnel inbound, host and groups through the API: `references/pasarguard.md` §18.
11. **Relay IP ranges differ, quotas run out, exits can have upload caps.** Ask for another range when a new one fails every test; check quotas when a relay works only from inside the country. `references/tunnels.md` §17, `references/iran-filtering.md` §5.
12. **Two services on one port 443** with an nginx SNI router: `references/tunnels.md` §18.
13. **Never pull a relay on one vantage point.** The operator's own connection failed while ~1,500 users were happily on the relay. Confirm from two in-country probes and the exit side. `references/cloudflare.md` §4.
14. **Keep the panel off Cloudflare's proxy in Iran.** Resolvers mapped proxied names to two slow addresses; put the panel port on GRE relays, get a certificate for the name, then go DNS-only. `references/pasarguard.md` §20.
15. **Raise PasarGuard's database pool.** The default 5+5 caused random panel failures; 20+40 and a container recreate fixed them. `references/pasarguard.md` §19.
16. **Move a throttled exit on a spare port first.** Re-point one relay's DNAT after testing, without flushing conntrack, and users drain across with no drop. `references/node-lifecycle.md` §12.
17. **Only addresses that pass a POST test belong in the panel domain.** One relay stalled order and renewal bodies over xDi and again over GRE, and was re-added by someone else a week later. `scripts/relay/panel_path_check.sh`, `references/pasarguard.md` §16.
18. **Run the inbound-group audit after every new node.** Two new exits had hosts and DNS but no group. `scripts/panel/inbound_groups.py`.
19. **Bots abroad, panels in the country:** a password-protected proxy on an in-country relay that accepts flows started abroad, open only to the bot's IP. `scripts/relay/bot_panel_proxy.sh`.
20. **After an exit reboots, check its ports, not the panel.** Two nodes showed `connected` for 1.5 hours with Xray stopped; re-saving them fixed it. `references/pasarguard.md` §12.
21. **Add xDi links to a relay one at a time.** Several at once got ICMP from abroad blocked within 20 minutes and killed every xDi link on that relay. `references/tunnels.md` §15.

More in [docs/field-observations-2026-10.md](docs/field-observations-2026-10.md).

</details>

<details>
<summary><b>What is in the repository</b></summary>

| Path | What it holds |
| --- | --- |
| [`SKILL.md`](SKILL.md) | Agent entrypoint: safety rules, triage flow, reference routing. |
| [`scripts/`](scripts/README.md) | Field-tested helpers: real users per relay, health, xDi test matrix, reviewed DNAT, GRE links, PasarGuard node edits and certificates, Cloudflare DNS and brand audit. |
| [`references/`](references/README.md) | Architecture, panels, tunnels, Cloudflare, incidents, capacity, Iran filtering, node lifecycle. |
| [`guides/panels/`](guides/panels/README.md) · [`guides/tunnels/`](guides/tunnels/README.md) | Runbooks for each major panel and tunnel family. |
| [`registries/`](registries/) | JSON inventories of panels, cores, tunnels, tools, and the community repositories reviewed. |
| [`docs/`](docs/) | Install recipes, networking recipes, ecosystem guide, source log, field observations, maintenance and release gates. |
| [`templates/fleet-inventory.example.md`](templates/fleet-inventory.example.md) | Private inventory template. Never commit a filled-in copy. |
| `metadata.json` · `agents/openai.yaml` | Package metadata for non-Claude runtimes and Codex. |
| `.github/workflows/` | Structure, JSON, link, secret-pattern and monthly source checks. |

</details>

<details>
<summary><b>Questions</b></summary>

**Will the agent change my servers on its own?** No. It stays read-only until you approve a specific change, and every change comes with its rollback. DNS, panel databases, subscriptions and credentials are never touched without your OK.

**Does the repository contain IPs, keys or subscription links?** No. It holds no secrets, credentials, API tokens, private keys or production inventories, and CI scans every commit for secret patterns. Keep your own inventory private.

**Are the install commands safe to run?** Only commands checked against public upstream sources are marked `verified`. Third-party installers and community scripts are labeled as such and treated as remote code execution: the agent reviews them before use.

**Which agents does it work with?** Claude Code and Codex out of the box. Any agent that can read Markdown and run shell commands can use it through `SKILL.md`.

</details>

## Community

VPNOpsNyx stands on the public work of maintainers who keep VPN, proxy, routing and anti-censorship tools open. Their repositories informed the community registry and source review:

[erfjabplus](https://github.com/erfjabplus) · [AsanFillter](https://github.com/AsanFillter) · [rezazoom](https://github.com/rezazoom) · [azavaxhuman](https://github.com/azavaxhuman) · [ircfspace](https://github.com/ircfspace) · [primeZdev](https://github.com/primeZdev) · [ppouria](https://github.com/ppouria) · [MHSanaei](https://github.com/MHSanaei)

And the panels, tunnels and tools referenced throughout:

[Azumi67](https://github.com/Azumi67) · [PasarGuard](https://github.com/PasarGuard) · [vpaneladmin](https://github.com/vpaneladmin) · [Gozargah](https://github.com/Gozargah) · [marzneshin](https://github.com/marzneshin) · [hiddify](https://github.com/hiddify) · [remnawave](https://github.com/remnawave) · [alireza0](https://github.com/alireza0) · [Musixal](https://github.com/Musixal) · [behzadea12](https://github.com/behzadea12) · [opiran-club](https://github.com/opiran-club) · [itsFLoKi](https://github.com/itsFLoKi) · [AminMGMT](https://github.com/AminMGMT)

Inclusion is recognition and source attribution, not a security endorsement. See [docs/community-review.md](docs/community-review.md) for repository-level notes.

## Contribute

New panels, tunnels, verified install steps, safer rollbacks, troubleshooting cases, source corrections and translations are all welcome. Fork the repository, make the change on a branch with authoritative source links, and open a pull request to `nyxon-tech/vpnopsnyx`. Read [CONTRIBUTING.md](CONTRIBUTING.md) first, and never include credentials, private keys, subscription URLs, production IPs or user data.

MIT licensed. Unofficial and not affiliated with any panel, tunnel or VPN project it documents.

<p align="center">
  <a href="https://github.com/nyxon-tech"><img src="./assets/readme/made-by-nyxon.svg" width="250" alt="Made by Nyxon"></a>
</p>
