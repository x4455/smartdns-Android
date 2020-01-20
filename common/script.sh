#!/system/bin/sh
MODDIR=/data/adb/modules/smartdns
[[ $(id -u) -ne 0 ]] && { echo "${MODDIR##\/*\/}: Permission denied"; exit 1; }

usage() {
	cat <<-EOF
Valid options are:
    -start
        Start Service
    -stop
        Stop Service
    -status
        Service Status
    --clean
        Clear all rules and stop server
    -h, --help
        Get help
    -p, --port [main / route] {port}
        Change port
    -u, --user [radio / root]
        Server permission
    --ip6block [true/false]
        Block IPv6 port 53 output or Redirect query
    --strict [true/false]
        Limit queries from non-LAN
EOF
	exit $1
}

## 防火墙
# 主控
iptrules_on() {
	iptrules_load $IPT -I
	ip6trules_switch -I
}

iptrules_off() {
	local i=0
	while iptrules_check; do
		iptrules_load $IPT -D
		ip6trules_switch -D
		[[ ${i} > 2 ]] && { echo 'Error: iptrules check Error'; exit 1; } || ((++i))
	done
}

ip6trules_switch() {
	if [ $IP6T_block ]; then
		$IP6T -t filter $1 OUTPUT -p tcp --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j REJECT --reject-with tcp-reset
		$IP6T -t filter $1 OUTPUT -p udp --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j DROP
	else
		iptrules_load $IP6T $1
	fi
}

# 加载
iptrules_load() {
	# $2  -I / -D
	echo "info: ${1##\/*\/} $2"

	for IPP in 'tcp' 'udp'
	do
		# DNS_LOCAL
		$1 -t nat $2 OUTPUT -p $IPP --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j REDIRECT --to-ports $Listen_PORT
		[ ${1} == $IPT ] \
		&& $1 -t nat $2 POSTROUTING -p $IPP -d 127.0.0.0/8 --dport $Listen_PORT -j SNAT --to-source 127.0.0.1 \
		|| $1 -t nat $2 POSTROUTING -p $IPP -d ::1/128 --dport $Listen_PORT -j SNAT --to-source ::1

		if [ $Strict ]; then
		# DNS_EXTERNAL
			$1 -t nat $2 PREROUTING -p $IPP -s 10.0.0.0/8 --dport 53 -j REDIRECT --to-ports $Route_PORT
			$1 -t nat $2 PREROUTING -p $IPP -s 192.168.0.0/16 --dport 53 -j REDIRECT --to-ports $Route_PORT
		else
			$1 -t nat $2 PREROUTING -p $IPP --dport 53 -j REDIRECT --to-ports $Route_PORT
		fi
	done
}

## 检查
# 防火墙
iptrules_check()
{
	if [ -n "`$IPT -t nat -S OUTPUT | grep -E "REDIRECT --to-ports ${Listen_PORT}"`" ]; then
		echo 'info: iprules √'; return 0
	else
		echo 'info: iprules ×'; return 1
	fi
}

# 服务器进程
service_check()
{
	if [ -n "`pgrep $CORE_BINARY`" ]; then
		echo 'info: Server √'; return 0
	else
		echo 'info: Server ×'; return 1
	fi
}

## 其他
# (重)启动服务器
core_start() {
	killall -9 $CORE_BINARY >/dev/null 2>&1
	sleep 1
	# setuidgid UID GID GROUPS
	$CORE_DIR/setuidgid $(id -u $ServerUID) $(id -g $ServerUID) $(id -g $ServerUID),$(id -g inet),$(id -g media_rw) $CORE_BOOT 2>&1
	sleep 3
	if [ service_check ]; then
		echo "info: Server start [$(date +'%d/%r')]"
		return 0
	else
		echo 'Error: start server failed.'
		exit 1
	fi
}

### Main
get_args() {
	while [ ${#} -gt 0 ]; do
		case "${1}" in
			-h|--help) # 帮助信息
				usage 0
				;;

			-start) # 启动
				Service='start'
				;;

			-stop) # 停止
				Service='stop'
				;;

			-status) # 检查状态
				Service='status'
				;;

			--clean) # 清除
				Service='clean'
				;;

				# 修改数值

			-p|--port) # 端口设定
				local i='(^[1-9][0-9]{0,3}$)|(^[1-5][0-9]{4}$)|(^6[0-5]{2}[0-3][0-5]$)'
				case "${2}" in
					m|main)
						if [ -n "$(echo $3 | grep -E $i)" ]; then
							save_value Listen_PORT $Listen_PORT
							Listen_PORT=$3
							shift 2
						else
							echo "Error: Invalid value: $3"
							exit 1
						fi
							;;
					r|route)
						if [ -n "$(echo $3 | grep -E $i)" ]; then
							save_value Route_PORT $Route_PORT
							Route_PORT=$3
							shift 2
						else
							echo "Error: Invalid value: $3"
							exit 1
						fi
						;;
					*)
						if [ -n "$(echo $2 | grep -E $i)" ]; then
							save_value Listen_PORT $Listen_PORT
							Listen_PORT=$2
							shift 1
						else
							echo "Error: Invalid value: $2"
							exit 1
						fi
						;;
				esac
				;;

			-u|--user) # 服务器权级
				case "${2}" in
					radio|root)
						save_value ServerUID $2
						ServerUID=$2
						;;
					*)
						echo "Error: Invalid value: $2"
						exit 1
						;;
				esac
				shift 1
				;;

			--ip6block) # IPv6
				case "${2}" in
					true|false)
						save_value IP6T_block $2 bool
						IP6T_block=$2
						;;
					*)
						echo "Error: Invalid value: $2"
						exit 1
						;;
				esac
				shift 1
				;;

			--strict) # 限制
				case "${2}" in
					true|false)
						save_value Strict $2 bool
						Strict=$2
						;;
					*)
						echo "Error: Invalid value: $2"
						exit 1
						;;
				esac
				shift 1
				;;

			*)
				echo "Error: Invalid argument: $1"
				usage 1
				;;

			esac
		shift 1
	done
}

process() {
	case "${Service}" in
		start) # 启动
			iptrules_off
			core_start && iptrules_on
			;;

		stop) # 停止
			iptrules_off
			killall -9 $CORE_BINARY >/dev/null 2>&1
			echo "info: Server stop [$(date +'%d/%r')]"
			;;

		status) # 检查状态
			server_check
			exit $?
			;;

		clean) # 清除所有防火墙规则
			local i
			for i in "$IPT" "$IP6T"
			do
				$i -t nat -F OUTPUT
				$i -t nat -F POSTROUTING
				$i -t nat -F PREROUTING
			done
			killall -9 $CORE_BINARY >/dev/null 2>&1
			echo "info: All clean [$(date +'%d/%r')]"
			;;
	esac
}

main() {
	Listen_PORT='6453'
	Route_PORT=''
	ServerUID='radio'
	IP6T_block=true
	Strict=true
	. $MODDIR/lib.sh || { echo "Error: Can't load lib!"; exit 1; }
	[ -z "$Route_PORT" ] && Route_PORT=$Listen_PORT

	if [ "${1}" == '--b' ]; then
		shift 1
		$CORE_DIR/$CORE_BINARY $*
	elif [ "${1}" == '-binary' ]; then
		shift 1
		$CORE_DIR/$CORE_BINARY -c $DATA_DIR/smartdns.conf $*
	else
		if [ -z "${1}" ]; then
			usage 0
		else
			get_args "$@"
			if [[ $value_change && -z "$Service" ]]; then
				local tmp
				echo -n "info: Do you want to restart the server (y/n): "
				read -r tmp
				[[ "$tmp" == 'y' || "$tmp" == 'Y' ]] && Service='start'
			fi
			process
		fi
	fi
}

main "$@"
