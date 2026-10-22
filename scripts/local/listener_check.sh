#!/bin/bash
# Check that every exit actually LISTENS on its tunnel ports. A PasarGuard node can show "connected" in the
# panel for hours while its Xray core is stopped (node log: "SyncUser ... Code: Unavailable"); then every
# relay path to that location fails and the panel gives no hint. Run it from the operator's workstation.
#
#   EXITS="exit-de:21001,21002 exit-nl:21003 exit-fi:21004" scripts/local/listener_check.sh
#     each item: SSH_HOST:PORT[,PORT...]
#
# A NOT-LISTENING port on a PasarGuard node: save the node again with the same address and port
# (scripts/panel/node_edit.sh) to restart its core, then rerun this check.
O="-o ConnectTimeout=30 -o ServerAliveInterval=5"
for x in ${EXITS:?set EXITS}; do
  h=${x%%:*}; ports=${x#*:}
  printf '%-22s ' "$h"
  ssh $O "$h" "for p in ${ports//,/ }; do ss -Hltn \"( sport = :\$p )\" | grep -q . && printf '%s=ok ' \$p || printf '%s=NOT-LISTENING ' \$p; done; echo" 2>&1 | tail -1
done
