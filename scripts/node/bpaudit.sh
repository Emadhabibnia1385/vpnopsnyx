#!/bin/bash
# Audit of every active BackPack unit on this host. Read-only. Run on relays and exits:
#   ssh HOST 'bash -s' < scripts/node/bpaudit.sh            # default 6 s byte-counter window
#   ssh HOST 'SECS=10 bash -s' < scripts/node/bpaudit.sh
# L4 forwarders ([server]/[client]): prints role, transport, accept_udp and the peer/bind address, and
# flags anything that is not the fleet standard (wsmux + accept_udp = true).
# L3 links ([l3], GRE/xDi): prints the interface byte-counter DELTA over the window. Judge an L3 link by
# that delta, never by TCP socket counts (a raw GRE carrier has no TCP sockets) or by ping (the far end
# often drops ICMP while real traffic flows). A link whose counters do not move for a full busy hour is
# the only safe "unused" signal; check the exit's real-user bytes before removing anything.
# Nothing is changed, stopped or deleted. Undo: not applicable.
SECS=${SECS:-6}
units=$(systemctl list-units --type=service --state=active --no-legend 'bp-*' 'backpack*' 2>/dev/null | awk '{print $1}')
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
for u in $units; do
  cfg=$(systemctl cat "$u" 2>/dev/null | sed -n 's/^ExecStart=.* -c \([^ ]*\).*/\1/p' | head -1)
  [ -f "$cfg" ] || continue                       # helper units (monitor, webui) have no tunnel config
  n=${u%.service}
  if grep -q '^\[l3\]' "$cfg"; then
    iface=$(awk -F'"' '/^iface/{print $2; exit}' "$cfg"); peer=$(awk -F'"' '/^addr/{print $2; exit}' "$cfg")
    rx=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null || echo 0)
    tx=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null || echo 0)
    echo "L3|$n|$iface|$peer|$rx|$tx" >> "$tmp"
  else
    role=$(grep -oE '^\[(server|client)\]' "$cfg" | head -1 | tr -d '[]')
    tr=$(awk -F'"' '/^transport/{print $2; exit}' "$cfg")
    udp=$(awk -F'=' '/^accept_udp/{gsub(/[ \r]/,"",$2); print $2; exit}' "$cfg")
    addr=$(awk -F'"' '/^(remote_addr|bind_addr)/{print $2; exit}' "$cfg")
    flag=OK
    [ "$tr" = wsmux ] || flag="NOTE transport=${tr:-?}"
    [ "$udp" = true ] || flag="$flag accept_udp=${udp:-unset}"
    printf 'L4  %-22s %-7s %-8s udp=%-6s %-24s %s\n' "$n" "${role:-?}" "${tr:-?}" "${udp:-unset}" "${addr:-?}" "$flag"
  fi
done
if [ -s "$tmp" ]; then
  sleep "$SECS"
  while IFS='|' read -r _ n iface peer rx0 tx0; do
    rx1=$(cat /sys/class/net/"$iface"/statistics/rx_bytes 2>/dev/null || echo 0)
    tx1=$(cat /sys/class/net/"$iface"/statistics/tx_bytes 2>/dev/null || echo 0)
    printf 'L3  %-22s iface=%-10s peer=%-22s rx=%s KB/s tx=%s KB/s (lifetime rx=%s MB tx=%s MB)\n' \
      "$n" "$iface" "$peer" "$(( (rx1-rx0)/SECS/1024 ))" "$(( (tx1-tx0)/SECS/1024 ))" "$((rx1/1048576))" "$((tx1/1048576))"
  done < "$tmp"
fi
echo "Active BackPack-related units on this host: $(systemctl list-units --type=service --state=active --no-legend 'bp-*' 'backpack*' | wc -l)"
