#!/system/bin/sh
### Make sure to stop the server
### before modifying the parameters
# Main listen port
Listen_PORT='6053'
# Route listen port
Route_PORT=''

# Service Mode
#  local: Proxy local only
#  proxy: Proxy local and External query
#  server: Expecting the server only
MODE='local'

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
	service_check
	[ "$?" != '3' ] && { change=true; iptrules_off; killall $CORE_BINARY >/dev/null 2>&1; }
	local tmp=$(grep "^$1=" $MODDIR/lib.sh)
	if [ -z "${3}" ]; then
		sed -i "s#^$tmp#$1=\'$2\'#g" $MODDIR/lib.sh
	else
		sed -i "s#^$tmp#$1=$2#g" $MODDIR/lib.sh
	fi
	return $?
}

## Check
iptrules_check()
{
	if [ -n "`$IPT -t nat -S | grep -E "REDIRECT --to-ports ${Listen_PORT}"`" ]; then
		echo 'info: iprules √'; return 0
	else
		echo 'info: iprules ×'; return 1
	fi
}

server_check()
{
	if [ -n "`pgrep $CORE_BINARY`" ]; then
		echo 'info: Server √'; return 0
	else
		echo 'info: Server ×'; return 1
	fi
}

service_check() {
	local i=0
	server_check || i=`expr $i + 2`
	[ $MODE == 'server' ] || iptrules_check || ((++i))

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
# legality
port_valid() {
	if [ -n "`echo $2 | grep -E '(^[1-9][0-9]{0,3}$)|(^[1-5][0-9]{4}$)|(^6[0-5]{2}[0-3][0-5]$)'`" ]; then
		return 0
	else
		echo "Error: Invalid value: $2"
		exit 1
	fi
}