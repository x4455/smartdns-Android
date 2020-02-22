#!/system/bin/sh
### Make sure to stop the server before modifying the parameters

# Main listen port
Listen_PORT='6053'
# Route listen port
Route_PORT=''

# Service Mode
#  proxy: Proxy local and other query
#  server: Expecting the server only
MODE='proxy'

# iptables block IPv6 port 53 [true/false]
# or Redirect query
IP6T_block=true

# Limit queries from non-LAN
Strict=true

# Server permission [radio/root] (Some operations may want to use root)
ServerUID='radio'

####################
### Don't modify it.
####################
# PATHs
IPT="/system/bin/iptables"
IP6T="/system/bin/ip6tables"

ROOT="/dev/dns_service/smartdns"

CORE_INTERNAL_DIR="$MODDIR/binary"
DATA_INTERNAL_DIR="/data/media/0/Android/smartdns"

CORE_DIR="$ROOT/binary"
DATA_DIR="$ROOT/config"

CORE_BINARY="smartdns-server"
CORE_BOOT="$CORE_DIR/$CORE_BINARY -c $DATA_DIR/smartdns.conf -p $ROOT/server.pid"

################
# Tool functions
################

save_value() {
	[ service_check != '3' ] && { iptrules_off; killall $CORE_BINARY >/dev/null 2>&1; value_change=true; }
	local tmp=$(grep "^$1=" $MODDIR/lib.sh)
	if [ -z "${3}" ]; then
		sed -i "s#^$tmp#$1=\'$2\'#g" $MODDIR/lib.sh
	else
		sed -i "s#^$tmp#$1=$2#g" $MODDIR/lib.sh
	fi
	return $?
}

service_check() {
	local i=0
	server_check || i=`expr $i + 2`
	[ $MODE == 'proxy' ] && iptrules_check || ((++i))

	case ${i} in
		3)  # Not working
			return 3 ;;
		2)  # Server not working
			return 2 ;;
		1)  # iptrules not load
			return 1 ;;
		0)  # Working
			return 0 ;;
	esac
}