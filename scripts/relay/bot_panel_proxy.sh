#!/bin/bash
# HTTP(S) proxy on an in-country server so a sales bot hosted ABROAD can reach panels hosted IN THE COUNTRY
# (many bots have a "panel proxy" field: http://user:pass@host:port). Only the bot's IP may use it, and it
# needs a password. Operator approval required: it opens a port on the server.
#
#   ssh IRAN_SERVER 'BOT_IP=198.51.100.7 bash -s' < scripts/relay/bot_panel_proxy.sh            # install
#   ssh IRAN_SERVER 'ACTION=status bash -s' < scripts/relay/bot_panel_proxy.sh
#   ssh IRAN_SERVER 'ACTION=allow BOT_IP=203.0.113.9 bash -s' < scripts/relay/bot_panel_proxy.sh # add a bot IP
#   ssh IRAN_SERVER 'ACTION=rotate bash -s' < scripts/relay/bot_panel_proxy.sh                  # new password
#   ssh IRAN_SERVER 'ACTION=remove bash -s' < scripts/relay/bot_panel_proxy.sh
# Optional: PORT (default 18799), PUBLIC_IP (default: detected), PROXY_USER (default botpanel).
#
# The full proxy URL (with the password) is written to /root/bot-panel-proxy.txt (mode 600) and never
# printed; read it on the server with `cat /root/bot-panel-proxy.txt` and paste it into the bot.
#
# Choose the server carefully: it must ACCEPT connections that start abroad (many in-country datacenters
# drop them) and reach the panels. Check first: on the server `timeout 300 python3 -m http.server 18799`,
# then from the bot server `curl -m 10 -o /dev/null -w '%{http_code}\n' http://SERVER:18799/` -> 200.
# No ConnectPort lines on purpose: tinyproxy's default config allows CONNECT only to 443/563, which breaks
# panels on 8000, 2053 and similar ports.
set -e
ACTION=${ACTION:-install}; PORT=${PORT:-18799}; PROXY_USER=${PROXY_USER:-botpanel}
CONF=/etc/tinyproxy/tinyproxy.conf; OUT=/root/bot-panel-proxy.txt
valid_ip() { [[ $1 =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; }
pubip() { [ -n "$PUBLIC_IP" ] && echo "$PUBLIC_IP" || ip -4 route get 1.1.1.1 | grep -oP 'src \K[0-9.]+'; }
newpass() { head -c 24 /dev/urandom | base64 | tr -dc A-Za-z0-9 | head -c 22; }
write_out() { printf 'http://%s:%s@%s:%s\n' "$PROXY_USER" "$1" "$(pubip)" "$PORT" > "$OUT"; chmod 600 "$OUT"; }
local_test() {
  local u; u=$(sed -E 's/@[^:]+:/@127.0.0.1:/' "$OUT")
  # an in-country site: the proxy exists to reach in-country panels, and foreign sites may be filtered here
  printf 'local test through proxy (TEST_URL): %s\n' "$(curl -s -m 15 -o /dev/null -w '%{http_code}' -x "$u" "${TEST_URL:-https://www.digikala.com/}" 2>/dev/null; true)"
}
case "$ACTION" in
  install)
    valid_ip "${BOT_IP:-}" || { echo "set BOT_IP to the bot server's IPv4"; exit 1; }
    ss -Hltn "( sport = :$PORT )" | grep -q . && ! grep -q "^Port $PORT$" "$CONF" 2>/dev/null && { echo "port $PORT is in use"; exit 1; }
    if ! command -v tinyproxy >/dev/null; then
      printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d   # do not auto-start on install
      DEBIAN_FRONTEND=noninteractive apt-get install -y -q tinyproxy >/tmp/tinyproxy-install.log 2>&1 || { rm -f /usr/sbin/policy-rc.d; tail -3 /tmp/tinyproxy-install.log; exit 1; }
      rm -f /usr/sbin/policy-rc.d
    fi
    [ -f "$CONF" ] && [ ! -f "$CONF.dist" ] && cp -a "$CONF" "$CONF.dist"
    P=$(newpass); umask 077
    cat > "$CONF" <<EOF
# Proxy for a sales bot abroad to reach panels in this country. Only the listed bot IPs may use it.
User tinyproxy
Group tinyproxy
Port $PORT
Listen 0.0.0.0
Timeout 120
MaxClients 200
LogLevel Warning
Syslog On
DisableViaHeader Yes
Allow 127.0.0.1
Allow $BOT_IP
BasicAuth $PROXY_USER $P
EOF
    chown root:tinyproxy "$CONF"; chmod 640 "$CONF"; write_out "$P"; unset P
    if ufw status 2>/dev/null | grep -q "Status: active"; then ufw allow from "$BOT_IP" to any port "$PORT" proto tcp >/dev/null; fi
    systemctl enable tinyproxy >/dev/null 2>&1; systemctl restart tinyproxy; sleep 1
    echo "tinyproxy $(systemctl is-active tinyproxy) on :$PORT, allowed: $BOT_IP; URL saved in $OUT"; local_test ;;
  allow)
    valid_ip "${BOT_IP:-}" || { echo "set BOT_IP"; exit 1; }
    grep -q "^Allow $BOT_IP$" "$CONF" || sed -i "/^Allow 127.0.0.1$/a Allow $BOT_IP" "$CONF"
    if ufw status 2>/dev/null | grep -q "Status: active"; then ufw allow from "$BOT_IP" to any port "$PORT" proto tcp >/dev/null; fi
    systemctl restart tinyproxy; echo "allowed: $(grep '^Allow' "$CONF" | cut -d' ' -f2 | tr '\n' ' ')" ;;
  rotate)
    P=$(newpass); sed -i -E "s/^BasicAuth ([^ ]+) .*/BasicAuth \1 $P/" "$CONF"; PROXY_USER=$(sed -nE 's/^BasicAuth ([^ ]+) .*/\1/p' "$CONF")
    PORT=$(sed -nE 's/^Port ([0-9]+)/\1/p' "$CONF"); write_out "$P"; unset P
    systemctl restart tinyproxy; echo "new password saved in $OUT (update the bot)"; local_test ;;
  status)
    echo "tinyproxy $(systemctl is-active tinyproxy 2>/dev/null || echo missing); port $(sed -nE 's/^Port ([0-9]+)/\1/p' "$CONF" 2>/dev/null); allowed: $(grep '^Allow' "$CONF" 2>/dev/null | cut -d' ' -f2 | tr '\n' ' ')"
    echo "open connections: $(ss -Htn state established "( sport = :$(sed -nE 's/^Port ([0-9]+)/\1/p' "$CONF" 2>/dev/null) )" 2>/dev/null | wc -l)"
    [ -f "$OUT" ] && local_test
    journalctl -u tinyproxy --since -1h --no-pager 2>/dev/null | grep -iE "denied|unauthor|error" | tail -5 ;;
  remove)
    systemctl disable --now tinyproxy >/dev/null 2>&1 || true; rm -f "$OUT"; echo "tinyproxy stopped and disabled; $OUT removed" ;;
  *) echo "ACTION must be install, allow, rotate, status or remove"; exit 1 ;;
esac
