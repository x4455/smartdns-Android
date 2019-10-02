# Listen port (Keep consistent with listen_addresses)
V4LPT=6453
V6LPT=6453

# Clear the log after booting
ClearList="
smartdns.log
smartdns-audit.log
"

## Enhanced

# iptables block port 53 INPUT #
ipt_block_INPUT=false
whitelist="
114.114.115.115
119.29.29.29
180.76.76.76
223.5.5.5
"

# If you device are not supported "IPv6 nat", set this option to "false"
# and remove IPv6 from "listen_addresses" in the config file.
# iptables block IPv6 port 53 #
ipt_block_IPv6_OUTPUT=false

## Constant (If you don't know what you are doing, don't modify it.)
IPTABLES=/system/bin/iptables
IP6TABLES=/system/bin/ip6tables

CONFIG=/data/media/0/smartdns/smartdns.conf

CORE_BINARY=smartdns-core
CORE_PATH=$MODPATH/$CORE_BINARY
CORE_BOOT="$CORE_PATH -c $CONFIG -p $MODPATH/core.pid"
