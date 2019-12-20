#!/system/bin/sh
### Make sure to stop the server before modifying the parameters

# Listening port set in the config
Listen_PORT=6453

# Server permission [radio/root] (Some operations may want to use root)
ServerUID='radio'

# iptables block IPv6 port 53 [true/false]
ip6t_block=true

# iptables anti-http 302 hijacking (insecure) [disable | lite | ultimate]
ipt_anti302='disable'



####################
### Don't modify it. ###
####################
# PATHs
#########
IPT=/system/bin/iptables
IP6T=/system/bin/ip6tables

ROOT=/dev/smartdns_root

CORE_INTERNAL_DIR="$MODDIR/core"
DATA_INTERNAL_DIR="/data/media/0/smartdns"

CORE_DIR="$ROOT/core"
DATA_DIR="$ROOT/config"

CORE_BINARY="smartdns-server"
CORE_BOOT="$CORE_DIR/$CORE_BINARY -c $DATA_DIR/smartdns.conf -p $ROOT/core.pid"

################
# Tool functions
################

save_value() {
	local tmp=$(grep "^$1=" $MODDIR/lib.sh)
	value_change=true
	if [ -z "${3}" ]; then
		sed -i "s#^$tmp#$1=\'$2\'#g" $MODDIR/lib.sh
	else
		sed -i "s#^$tmp#$1=$2#g" $MODDIR/lib.sh
	fi
	return $?
}