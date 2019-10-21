# Listen port (Keep consistent with listen_addresses)
LPORT=6453

## Enhanced

# If you device are not supported "IPv6 nat", set this option to "true"
# iptables block IPv6 port 53 #
ipt_block_IPv6_OUTPUT=true

## Constant (If you don't know what you are doing, don't modify it.)
IPTABLES=/system/bin/iptables
IP6TABLES=/system/bin/ip6tables
UID='0'

CONFIG=/sdcard/smartdns/smartdns.conf

CORE_BINARY=smartdns-core
CORE_PATH=$MODDIR/$CORE_BINARY
CORE_BOOT="$CORE_PATH -c $CONFIG -p $MODDIR/core.pid"
