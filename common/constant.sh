# Listen port (Keep consistent with listen_addresses)
LPORT=6453

## Enhanced

# Redirect protocol (eg. "udp tcp"
protocol="udp"

# If you device are not supported "IPv6 nat", set this option to "true"
# iptables block IPv6 port 53
ipt_block_v6=true

## Constant ##(If you don't know what you are doing, don't modify it.)
# Service permission (Some operations may want to use root)
ServerUID='radio'

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
