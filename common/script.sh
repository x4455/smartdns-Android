#!/system/bin/sh
MODDIR=/data/adb/modules/smartdns
[[ $(id -u) -ne 0 ]] && { echo "${MODDIR##\/*\/}: Permission denied"; exit 1; }

usage() {
	cat <<-EOF
Valid options are:
    -start
        Start Server
    -stop
        Stop Server
    -status
        Server Status
    -usage
        Get help
    -user [radio / root]
        Server permission
    -anti302 [disable | lite | ultimate]
        Anti-http 302 hijacking (insecure)
    -ip6block [true/false]
        Block IPv6 port 53 output
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
		[[ ${i} > 2 ]] && { echo 'error: iptrules check error'; exit 1; } || ((++i))
	done
}

ip6trules_switch() {
	# ip6block [true/false]
	if [ $ip6t_block ]; then
		$IP6T -t filter $1 OUTPUT -p udp --dport 53 -j DROP
		$IP6T -t filter $1 OUTPUT -p tcp --dport 53 -j REJECT --reject-with tcp-reset
	else
		iptrules_load $IP6T $1
	fi
}

# 加载
iptrules_load() {
	echo "info: ${1##\/*\/} $2"

	# 新建规则
	if [ "${2}" == '-I' ]; then
		$1 -t nat -N DNS_LOCAL
	fi

	for IPP in 'tcp' 'udp'
	do
		# DNS_LOCAL
		$1 -t nat $2 OUTPUT -p $IPP --dport 53 -j DNS_LOCAL
		$1 -t nat $2 DNS_LOCAL -p $IPP -j REDIRECT --to-ports $Listen_PORT
		$1 -t nat $2 POSTROUTING -p $IPP -d 127.0.0.1/32 --dport $Listen_PORT -j SNAT --to-source 127.0.0.1
		# DNS_EXTERNAL
		$1 -t nat $2 PREROUTING -p $IPP --dport 53 -j REDIRECT --to-ports $Route_PORT
	done

	if [ "${2}" == '-D' ]; then
		# 清除规则
		$1 -t nat -F DNS_LOCAL
		$1 -t nat -X DNS_LOCAL
	else
		$1 -t nat $2 DNS_LOCAL -m owner --uid-owner $(id -u $ServerUID) -j RETURN
	fi

	# anti http 302 [ disable | lite | normal | ultimate ]
	if [ "$ipt_anti302" != 'disable' ]; then
		case "${ipt_anti302}" in
			lite)
				$1 $2 INPUT -p tcp -m tcp --sport 80 --tcp-flags SYN,RST,URG FIN,PSH,ACK -j DROP
				;;
			#normal) $1 $2 INPUT -p tcp -m tcp --sport 80 -j DROP ;;
			ultimate)
				$1 $2 INPUT -p tcp -m tcp --sport 80 --tcp-flags FIN,SYN,RST,PSH,ACK,URG PSH,ACK -m string --algo bm --from 45 --to 80 --string "302 Found" -j DROP
				;;
			*)
				echo "WARNING: Invalid value: $ipt_anti302"
				;;
		esac
	fi
	echo "info: Anti302 [ $ipt_anti302 ]"
}

## 检查
# 防火墙
iptrules_check()
{
	if [ -n "`$IPT -t nat -S OUTPUT | grep 'DNS_LOCAL'`" ]; then
		echo 'info: iprules √'; return 0
	else
		echo 'info: iprules ×'; return 1
	fi
}

# 核心进程
core_check()
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
	killall $CORE_BINARY 2>/dev/null
	sleep 1
	# setuidgid UID GID GROUPS
	$CORE_DIR/setuidgid $(id -u $ServerUID) $(id -g $ServerUID) $(id -g $ServerUID),$(id -g inet),$(id -g media_rw) $CORE_BOOT 2>&1
	sleep 3
	if core_check; then
		echo "info: Server start [$(date +'%d/%r')]"
		return 0
	else
		echo 'error: start server failed.'
		exit 1
	fi
}

### main
get_args() {
	Listen_PORT='6453'
	Route_PORT=''
	ServerUID='radio'
	ip6t_block=true
	ipt_anti302='disable'
	. $MODDIR/lib.sh || exit 1
	[ -z "$Route_PORT" ] && Route_PORT=$Listen_PORT

	while [ ${#} -gt 0 ]; do
		case "${1}" in
			-usage) # 帮助信息
				usage 0
				;;

			-start) # 启动
				Server='start'
				;;

			-stop) # 停止
				Server='stop'
				;;

			-status) # 检查状态
				service_check
				exit $?
				;;

				# 修改数值

			-port) # 端口设定
				local i='(^[1-9][0-9]{0,3}$)|(^[1-5][0-9]{4}$)|(^6[0-5][0-5][0-3][0-5]$)'
				case "${2}" in
					main)
						if [ -n "$(echo $3 | grep -E $i)" ]; then
							Listen_PORT=$3
							save_value Listen_PORT $Listen_PORT
							shift 2
						else
							echo "Error: Invalid value: $3"
							exit 1
						fi
							;;
					route)
						if [ -n "$(echo $3 | grep -E $i)" ]; then
							Route_PORT=$3
							save_value Route_PORT $Route_PORT
							shift 2
						else
							echo "Error: Invalid value: $3"
							exit 1
						fi
						;;
					*)
						if [ -n "$(echo $2 | grep -E $i)" ]; then
							Listen_PORT=$2
							save_value Listen_PORT $Listen_PORT
							shift 1
						else
							echo "Error: Invalid value: $2"
							exit 1
						fi
						;;
				esac
				;;

			-user) # 服务器权级
				case "${2}" in
					radio|root)
						ServerUID=$2
						save_value ServerUID $2
						;;
					*)
						echo "Error: Invalid value: $2"
						exit 1
						;;
				esac
				shift 1
				;;

			-anti302)
				case "${2}" in
					disable|lite|normal|ultimate)
						ipt_anti302=$2
						save_value ipt_anti302 $2
						;;
					*)
						echo "Error: Invalid value: $2"
						exit 1
						;;
				esac
				shift 1
				;;

			-ip6block)
				case "${2}" in
					true|false)
						ip6t_block=$2
						save_value ip6t_block $2 bool
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
	if [ $value_change -a service_check ]; then
		echo -e 'info: value change !\ninfo: restart server !'
		Server='start'
	fi

	case "${Server}" in
		start) # 启动
			iptrules_off
			core_start && iptrules_on
			;;

		stop) # 停止
			iptrules_off
			killall $CORE_BINARY 2>/dev/null
			echo "info: Server stop [$(date +'%d/%r')]"
			;;
	esac
}

main() {
	if [ -z "${1}" ]; then
		usage 0
	else
		get_args "$@"
		process
	fi
}

main "$@"
