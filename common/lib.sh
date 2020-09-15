#!/system/bin/sh
### Make sure to stop the server
### before modifying the parameters
# Main listen port
Listen_PORT='6053'
# Route listen port
Route_PORT='6553'

# Service Mode
# Server | Local rules | Proxy rules
# (null) | L | P
mode='L'

# Redirect tun+
vpn=false

# Accept query (Package_name or UID)
pkg='com.github.shadowsocks com.github.kr328.clash'

# Block IPv6 port 53 or Redirect query
IP6T_block=false

# Limit queries from non-LAN
strict=true

# Server permission [radio/root] (`bind :53` or `speed-check-mode ping` want to use root)
ServerUID='root'

# Boot tools script (Leave blank to execute all or 'disable')
tools='disable'



####################
# Don't modify it. # Don't modify it. # Don't modify it.
# PATHs
IPT="/system/bin/iptables"
IP6T="/system/bin/ip6tables"

ROOT="/dev/smartdns"

CORE_INTERNAL_DIR="$MODDIR/binary"
DATA_INTERNAL_DIR="/data/adb/smartdns"

CORE_DIR="$ROOT/binary"
DATA_DIR="$ROOT/config"
PID_file="$ROOT/server.pid"
CORE_BINARY="smartdns-server"
CORE_BOOT="$CORE_DIR/$CORE_BINARY -c $DATA_DIR/smartdns.conf -p $PID_file"

#####
# Lib functions
server_start() {
	# setuidgid [UID GID GROUPS]
	$CORE_DIR/setuidgid $(id -u $ServerUID) $(id -g $ServerUID) $(id -g $ServerUID),$(id -g inet),$(id -g media_rw) $CORE_BOOT
	if [ server_check ]; then
		echo "[Info]: Server start [$(date +'%d/%r')]"
		return 0
	else
		echo '[Error]: start server failed.'
		exit 1
	fi
}

save_values() {
	[ iptrules_check -o server_check ] && { iptrules_off; kill -s 9 `cat $PID_file`; echo '[Info]: Server stop'; }
	local tmp=$(grep "^${1}=" $MODDIR/lib.sh)
	if [ "${2}" != 'bool' ]; then
		sed -i "s#^$tmp#${1}=\'${2}\'#g" $MODDIR/lib.sh
	else
		if [ "${3}" == 'true' -o "${3}" == 'false' ]; then
			sed -i "s#^$tmp#${1}=${3}#g" $MODDIR/lib.sh
		elif [[ "${3}" == -* || -z "${3}" ]]; then
			if [ "$(echo $tmp |awk -F "=" '{print $2}')" == 'true' ]; then
				sed -i "s#^$tmp#${1}=false#g" $MODDIR/lib.sh
				return 2
			else
				sed -i "s#^$tmp#${1}=true#g" $MODDIR/lib.sh
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
	[ -f $PID_file ] && local cmd_file="/proc/`cat $PID_file`/cmdline" || return 1
	[ -f $cmd_file ] && grep -q $CORE_DIR/$CORE_BINARY $cmd_file && return 0 || return 1
}

service_check() {
	local i=0 a=0
	server_check && echo '[Info]: Server √' || { echo '[Info]: Server ×'; let i+=2; }
	if [ -n "$mode" ]; then
		if echo $mode |grep -q 'L'; then
			$IPT -t nat -S OUTPUT |grep -q -E "REDIRECT.+$Listen_PORT" || { let a--; echo '[Warning]: LocalRules not added.'; }
		fi
		if echo $mode |grep -q 'P'; then
			$IPT -t nat -S PREROUTING |grep -q -E "REDIRECT.+$Route_PORT" || { let a--; echo '[Warning]: ProxyRules not added.'; }
		fi
		if [ "$a" -eq 0 ]; then
			echo '[Info]: iprules √'
		else
			echo '[Info]: iprules ×'; let i++
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