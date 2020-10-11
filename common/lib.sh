#!/system/bin/sh
# Don't modify it. # Don't modify it. # Don't modify it.
# PATHs
IPT="/system/bin/iptables"
IP6T="/system/bin/ip6tables"

ROOT="/dev/smartdns"

CORE_INTERNAL_DIR="$MODDIR/binary"
DATA_INTERNAL_DIR="/data/adb/smartdns-data"

CORE_DIR="$ROOT/binary"
DATA_DIR="$ROOT/config"

SET_FILE="$DATA_INTERNAL_DIR/script.conf"
PIDFILE="$ROOT/server.pid"

CORE_BINARY="smartdns-server"
CORE_BOOT="$CORE_BINARY -c $DATA_DIR/smartdns.conf -p $PIDFILE"
#CORE_BOOT="$CORE_DIR/$CORE_BINARY

##############
# Lib functions
server_start() {
	# setuidgid [UID GID GROUPS]
	cd $CORE_DIR
	./setuidgid $(id -u $ServerUID) $(id -g $ServerUID) $(id -g $ServerUID),$(id -g inet),$(id -g media_rw) $CORE_BOOT
	cd - 1>/dev/null
	#$CORE_DIR/setuidgid

	while true; do
		if [ -e "$PIDFILE" ]; then
			break;
		fi
		sleep .5
	done
	PID="$(cat $PIDFILE 2>/dev/null)"
	if [ -z "$PID" ]; then
		echo '[Error]: start smartdns server failed.'
		exit 1
	fi
	if [ ! -e "/proc/$PID" ]; then
		echo '[Error]: start smartdns server failed.'
		exit 1
	fi
	echo '[Info]: start smartdns server success.'
}

server_stop() {
	if [ ! -f "$PIDFILE" ]; then
		echo '[Info]: smartdns server is stopped.'
		return 0
	fi
	PID="$(cat $PIDFILE 2>/dev/null)"
	if [ ! -e "/proc/$PID" ] || [ -z "$PID" ]; then
		echo '[Info]: smartdns server is stopped'
		return 0
	fi

	kill -TERM "$PID"
	if [ $? -ne 0 ]; then
		echo '[Error]: Stop smartdns server failed.'
		exit 1;
	fi
	rm -f "$PIDFILE"
	echo '[Info]: Stop smartdns server success.'
}

save_values() {
	[ iptrules_check -o server_check ] && { iptrules_off; server_stop; echo '[Info]: Server stop'; }
	local tmp=$(grep "^${1}=" $SET_FILE)
	if [ "${2}" != 'bool' ]; then
		sed -i "s#^$tmp#${1}=\'${2}\'#g" $SET_FILE
	else
		if [ "${3}" == 'true' -o "${3}" == 'false' ]; then
			sed -i "s#^$tmp#${1}=${3}#g" $SET_FILE
		elif [[ "${3}" == -* || -z "${3}" ]]; then
			if [ "$(echo $tmp |awk -F "=" '{print $2}')" == 'true' ]; then
				sed -i "s#^$tmp#${1}=false#g" $SET_FILE
				return 2
			else
				sed -i "s#^$tmp#${1}=true#g" $SET_FILE
				return 1
			fi
		else
			echo "[Error]: Invalid value: $3"
			exit 1
		fi
	fi
	return 0
}

# Check
iptrules_check() {
	if $IPT -t nat -S |grep -q -E "REDIRECT.+($Listen_PORT|$Route_PORT)$"; then
		return 0
	else
		return 1
	fi
}

server_check() {
	if [ ! -f "$PIDFILE" ]; then
		return 1
	fi
	PID="$(cat $PIDFILE 2>/dev/null)"
	if [ ! -e "/proc/$PID" ] || [ -z "$PID" ]; then
		return 1
	fi
	return 0
}

service_check() {
	local i=0 a=0
	server_check && { echo '[Info]: server is working.'; } || { echo '[Info]: server is stopped'; let i+=2; }
	if [ -n "$mode" ]; then
		if echo $mode |grep -q 'L'; then
			$IPT -t nat -S OUTPUT |grep -q -E "REDIRECT.+$Listen_PORT" || { let a--; echo '[Warning]: LocalRules not added.'; }
		fi
		if echo $mode |grep -q 'P'; then
			$IPT -t nat -S PREROUTING |grep -q -E "REDIRECT.+$Route_PORT" || { let a--; echo '[Warning]: ProxyRules not added.'; }
		fi
		if [ "$a" -eq 0 ]; then
			echo '[Info]: iptables rules loaded.'
		else
			echo '[Info]: iptables rules not load.'; let i++
		fi
	fi
	case $i in
		3)  # Not working
			return 3 ;;
		2)  # Server not working
			return 2 ;;
		1)  # iptrules not added
			return 1 ;;
		0)  # Working
			return 0 ;;
	esac
}

# Legality
port_valid() {
	if echo $2 |grep -q -E '(^[1-9][0-9]{0,3}$)|(^[1-5][0-9]{4}$)|(^6[0-5]{2}[0-3][0-5]$)'; then
		return 0
	else
		echo "[Error]: Invalid value: $2"
		exit 1
	fi
}