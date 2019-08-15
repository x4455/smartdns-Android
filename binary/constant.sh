# If you device are not supported "IPv6 nat", set this option to "false"
# and remove IPv6 from "listen_addresses" in the config file.
#####
#ipt_setIPv6=false

# iptables block IPv6 port 53 #
ipt_blockIPv6=true

ClearList="
smartdns.log
smartdns-audit.log
"

# Constant (If you don't know what you are doing, don't modify it.)
IPTABLES=/system/bin/iptables
IP6TABLES=/system/bin/ip6tables

CONFIG="/system/etc/smartdns"

CORE_BINARY=smartdns-core
CORE_PATH=$MODPATH/$CORE_BINARY
CORE_BOOT="$CORE_PATH -p $MODPATH/smartdns.PID"  ## With "&"
