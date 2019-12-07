### Make sure to stop the service before modifying the parameters

# Listen port
LPORT=6453


## Enhanced

# Service permission [root/radio] (Some operations may want to use root)
ServerUID='radio'

# Redirect protocol [udp|tcp]
protocol="udp tcp"

# iptables block IPv6 port 53 [true/false]
ipt_block_v6=true



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
