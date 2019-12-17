### Make sure to stop the server before modifying the parameters

# Listening port set in the config
Listen_PORT=6453

# Server permission [radio/root] (Some operations may want to use root)
ServerUID='radio'

# iptables block IPv6 port 53 [true/false]
ip6t_block=true

# iptables anti-http 302 hijacking [true/false]
ipt_anti302=false


## Constant  (If you don't know what you are doing, don't modify it.)

# path
IPT="/system/bin/iptables"
IP6T="/system/bin/ip6tables"

ROOT="/dev/smartdns_root"

CORE_INTERNAL_DIR="$MODDIR/core"
DATA_INTERNAL_DIR="/data/media/0/smartdns"

CORE_DIR="$ROOT/core"
DATA_DIR="$ROOT/config"

CORE_BINARY="smartdns-server"
CORE_BOOT="$CORE_DIR/$CORE_BINARY -c $DATA_DIR/smartdns.conf -p $ROOT/core.pid"
