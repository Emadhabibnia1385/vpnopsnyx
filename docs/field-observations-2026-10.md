# Sanitized Field Observations - October 2026

## Scope And Trust

Continuation of `field-observations-2026-09.md`: the same operator, two brands, several Iranian
relay datacenters. Names, addresses, domains and tokens are removed. Everything here is
`operator-observed`.

## Repeated Patterns

- Relay-dialed xDi links were filtered per destination, often overnight; exit-dialed (reverse) links
  survived the same events and also served an exit whose IP was blacklisted for inbound traffic.
- One exit host could keep only one dialed xDi link working at a time.
- New paths were sometimes filtered within an hour of carrying traffic; next-day re-verification caught
  it, a 10-minute check did not.
- In-country datacenters throttled bulk traffic to a foreign IP while ping and small HTTPS stayed fine.
- A relay's exhausted traffic quota looked exactly like a datacenter outage.
- Sales bots hosted abroad must not reach the panel through in-country relays.
- Moving PasarGuard nodes to a new IP required new node certificates because the panel's TLS check is
  strict and pins the stored certificate.
- An exit with high download but a capped upload, and heavy loss to its panel, failed in ways that no
  relay change could fix.
- Plain GRE worked from one relay datacenter to every exit with almost no CPU, and was blocked in
  another; it has no per-exit dial limit, unlike xDi.
- A datacenter rotated relay IPs repeatedly; the new range blocked GRE and bulk TCP, accepted only
  exit-dialed xDi for about a day, and then lost that too.
- A second dialed xDi link on an exit passed a first test and died within minutes, four times out of four.
- An xDi relay behind the panel domain let reads through but stalled `POST`/`PUT` bodies, so a sales
  bot's renewals failed.
- Dead xDi links still consumed CPU on an already saturated relay.
- Panel access logs showed one address failing ~20,000 logins a day for days without anyone noticing.
- A direct panel IP passed login checks but stalled page and subscription downloads from most in-country
  datacenters; half of the users had broken subscription links.
- Deleting the last record of a name left users on cached NXDOMAIN for up to 30 minutes after a fix.
- A tunnel inbound in no group had zero users although every path worked.
- Relay IP rotations landed in good and bad ranges; one relay's international quota ran out twice in a week.
- Exits with a provider upload cap (high download, single-digit Mbit upload) could not be helped by any tunnel.
- One port can serve two services through an SNI router; a host allowlist in the raw table can still hide
  the new one from its clients.

- One evening the operator's own connection failed to every relay port while other datacenters reached
  them; a relay pulled from DNS on that evidence had to be put back.
- A busy panel's database pool at the default 5+5 produced intermittent failures; 20+40 ended them.
- In-country resolvers mapped Cloudflare-proxied names to two fixed addresses that were slow or dead from
  some datacenters; DNS-only names on relays worked.
- Turning a proxied subscription name DNS-only needed a matching origin certificate first, and its
  HTTP renewal will fail once the name points at in-country relays.
- A throttled exit's users were moved to another exit by re-pointing one relay's DNAT, tested on a spare
  port first; without a conntrack flush, users drained across with no visible drop.
- Servers rebuilt or resized by the provider came back with new SSH host keys or fewer cores.

## Late October - Obfuscated Tunnel Engine, Tuning, And Cutovers

- An obfuscated userspace tunnel (TCP stealth-style transport) bypassed the in-country to foreign
  throttle completely, while raw TCP/UDP/GRE to the same foreign exit saw near-total loss; a "no tunnel
  works" conclusion drawn from the raw tests alone was wrong, and the obfuscated engine had to be tested
  directly before judging a path dead.
- That engine's default minimal config dropped new-connection dials in bursts under a connection storm:
  users connected (handshake went "green") then stalled mid-stream, worst while scrolling video. Raising
  the tunnel's channel/queue size and socket buffers, switching to the aggressive preset, and adding
  keepalive/heartbeat ended the dial-cancel bursts with no change of transport.
  **Size those buffers to the relay's RAM.** The same tuning (32 MB socket buffers, an 8192-entry
  channel, aggressive preset) across six tunnels on a 2 GB relay used 250-530 MB per tunnel process; the
  kernel OOM-killed the busiest tunnel every 5-15 minutes, and every kill dropped all of its users at once
  ("connected, then disconnected again"). Swap stopped the kills; more RAM or smaller buffers fixed it.
  Watch `journalctl -k | grep "Out of memory"` and the tunnel units' restart counters after any change.
- Converting a relay's cheap kernel DNAT forwarding to the userspace tunnel bypassed throttle but cost
  real CPU. A 2-core relay that also ran L3/ICMP-carrier tunnels could not also carry obfuscated tunnels
  for every exit; its load was softirq (packet processing) dominated, not the tunnel process's own CPU,
  and the L3/ICMP-carrier links were the heaviest softirq source.
- A DNAT-to-tunnel cutover caused a reconnect storm - every affected user reconnecting at once - that
  spiked the relay to near-zero idle for a few minutes. Read as steady-state overload it caused a
  needless relay disable; the storm settled and the same 2-core relay then carried the load fine. Wait
  out a cutover before judging a relay's steady-state load.
- "Connects green then times out" had several distinct causes that only live data told apart: an
  overloaded relay dropping packets, a dead IP left in round-robin DNS, the user's own data quota
  exhausted, and a relay's traffic quota exhausted (which cuts the international path while the box stays
  reachable in-country).
- Two IPs of the same exit host differed wildly - one 0% loss with sub-millisecond jitter, the other
  20-25% loss - so a latency-sensitive target (for example a WireGuard endpoint) must be chosen by
  probing the specific IP, not the host name.
- A wiped/rebuilt exit needed both its panel node re-added (new certs) and every tunnel client rebuilt
  from scratch; the tunnel binary was copied from a sibling relay rather than re-run from a remote
  installer.
- Spreading one exit across several relays by round-robin DNS added redundancy, but every added relay is
  another IP that some in-country ISP may not reach well - a relay bad from one network times out only
  the users on that network, so more relays is not strictly better, and a too-small relay added to the
  rotation hurts rather than helps.

## Handling Rule

Same as September: prefer live evidence and the deployed version's behavior, label new findings, and
never expose the operator's inventory.
