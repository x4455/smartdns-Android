#!/system/bin/sh
MODDIR=/data/adb/modules/smartdns
[ ! -d $ROOT ] && { echo "${MODDIR##\/*\/}: Module disabled."; exit 1; }

usage() {
cat << HELP
Valid options are:
	-start
		Start Service
	-stop
		Stop Service
	-status
		Service Status
	-clean
		Restore origin rules and stop server
	-m, --mode [ local / proxy / server ]
		├─ local: Proxy local only
		├─ proxy: Proxy local and other query
		└─ server: Expecting the server only
	-p, --port [ main / route ] {port}
		Change port
	--ip6block [ true/false ]
		Block IPv6 port 53 output or Redirect query
	--vpn [ true/false ]
		Redirect VPN query
	--strict [ true/false ]
		Limit queries from non-LAN
	-u, --user [ radio / root ]
		Server permission
HELP
	exit $1
}

## 防火墙
# 主控
iptrules_on() {
	[ -z "$mode" ] && return 0
	if grep -q '^bind-tcp' $DATA_DIR/smartdns.conf ; then
		redirect_p='udp tcp'
	else
		redirect_p='udp'
	fi
	iptrules_load $IPT -A
	ip6trules_switch -A
}

iptrules_off() {
	[ -z "$mode" ] && return 0
	local i=0
	redirect_p='udp tcp'
	while iptrules_check
	do
		iptrules_load $IPT -D
		ip6trules_switch -D
		[[ ${i} > 3 ]] && { echo '[Error]: iptrules error.\n[Warning]: Run \`~ -clean\` to reset iptrules.'; exit 1; } || let i++
	done
}

ip6trules_switch() {
	if [ "$IP6T_block" == 'true' ]; then
		iptrules_accept $IP6T 'filter' $1 'udp'
		iptrules_accept $IP6T 'filter' $1 'tcp'
		$IP6T -t filter $1 OUTPUT $vpn -p udp --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j DROP
		$IP6T -t filter $1 OUTPUT $vpn -p tcp --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j REJECT --reject-with tcp-reset
	else
		iptrules_load $IP6T $1
	fi
}

# 加载
iptrules_load() {
	echo "[Info]: ${1##\/*\/} $2"
	# [iptables/ip6tables]  [-A/-D]
	local IP IPP

	for IPP in $redirect_p
	do
		#RAW表处理后会跳过NAT表和ip_conntrack
		iptrules_accept $1 'raw' $2 $IPP
		# LOCAL
		if echo $mode |grep -q 'L'; then
			$1 -t nat $2 OUTPUT $vpn -p $IPP --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j MARK --set-xmark 0x653
			$1 -t nat $2 OUTPUT -p $IPP -m mark --mark 0x653 -j REDIRECT --to-ports $Listen_PORT
			if [ "$1" == "$IPT" ]; then
				$1 -t nat $2 POSTROUTING -p $IPP -m mark --mark 0x653 -j SNAT --to-source 127.0.0.1
				iptrules_strict $1 $2 $IPP
			else
				$1 -t nat $2 POSTROUTING -p $IPP -m mark --mark 0x653 -j SNAT --to-source ::1
			fi
		fi
		# EXTERNAL
####	代理模式目前仍有问题
		if echo $mode |grep -q 'P'; then
			if [ "$1" == "$IPT" ]; then
				for IP in "$(ifconfig |grep "inet addr" |grep -v ":127" |grep "Bcast" |awk '{print $2}' |awk -F: '{print $2}')"
				do
					# 忘记什么操作了
					[ "$strict" != 'true' ] && echo $IP |grep -q -E '(^192\.168\.*)|(^10\.*)' && continue
					# IPv4 EXTERNAL
					$1 -t nat $2 PREROUTING -p $IPP -d "$IP" --dport 53 -j REDIRECT --to-ports $Route_PORT
				done
			fi
			#	放弃v6代理# IPv6 EXTERNAL
			#	$1 -t nat $2 PREROUTING -p $IPP --dport 53 -j REDIRECT --to-ports $Route_PORT
		fi
	done
}

iptrules_strict(){
	[ "$strict" != 'true' ] && return 0
	# [iptables]  [-A/-D]  [udp/tcp]
	local Intranet

	$1 -t filter $2 INPUT -p $3 -s "127.0.0.1" --dport $Listen_PORT -j ACCEPT
	if echo $mode |grep -q 'P'; then
		for Intranet in '192.168.0.0/16' '10.0.0.0/8'; do
			$1 -t filter $2 INPUT -p $3 -s "$Intranet" --dport $Route_PORT -j ACCEPT
		done
		[ "$Route_PORT" != "$Listen_PORT" ] && $1 -t filter $2 INPUT -p $3 --dport $Route_PORT -j DROP
	fi
	$1 -t filter $2 INPUT -p $3 --dport $Listen_PORT -j DROP
}

iptrules_accept() {
	[ -z "$pkg" ] && return 0
	# [iptables/ip6tables]  [raw->mangle->nat->filter]  [-A/-D]  [udp/tcp]
	local uid

	for uid in $pkg
	do
		echo $uid |grep -q -i '[a-z]' && uid=$(grep -m1 -i $uid /data/system/packages.list |cut -d' ' -f2); [ -z "$uid" ] && continue
		$1 -t $2 $3 OUTPUT -p $4 --dport 53 -m owner --uid-owner $uid -j ACCEPT
	done
}

###
get_args() {
	while [ ${#} -gt 0 ]; do
	case "$1" in
		-h|--help) # 帮助信息
			usage 0
			;;

		-start) # 启动
			#貌似没必要
			case "$2" in
				ser*)
					server_stop && sleep .5
					server_start
					echo "[Info]: Server started."
					shift
					;;
				ipr*)
					iptrules_off
					iptrules_on
					echo "[Info]: iptrules added."
					shift
					;;
				*)
					server_stop
					iptrules_off
					server_start && iptrules_on
					echo "[Info]: Service started."
					;;
			esac
			;;

		-stop) # 停止
			iptrules_off
			server_stop
			;;

		-status) # 检查状态
			service_check
			exit $?
			;;

		-clean) # 清除
			echo '[Info]: Flushing iptables...'
			iptables -F
			ip6tables -F
			iptables-restore < $ROOT/iptables.origin
			ip6tables-restore < $ROOT/ip6tables.origin
			server_stop
			echo '[Info]: All clean.'
			;;

		# 修改数值
		-p|--port) # 端口设定
			case "$2" in
				r*)
					shift; if [ port_valid ]; then
						save_values Route_PORT $2
						Route_PORT=$2
					fi
					;;
				*)
					[[ "$2" == m* ]] && shift
					if [ port_valid ]; then
						save_values Listen_PORT $2
						Listen_PORT=$2
					fi
					;;
			esac
			shift
			;;

		-m|--mode) # 工作模式
			case "$2" in
				'local')
					save_values mode 'L'
					mode='L'
					;;
				'proxy')
					save_values mode 'LP'
					mode='LP'
					;;
				'server')
					save_values mode ''
					mode=''
					;;
				*)
					echo "[Error]: Invalid value: $2"
					exit 1
					;;
			esac
			shift
			;;

		-u|--user) # 身份
			case "$2" in
				root|radio)
					save_values ServerUID $2
					ServerUID=$2
					;;
				*)
					echo "[Error]: Invalid value: $2"
					exit 1
					;;
			esac
			shift
			;;

		--ip6block) # IPv6
			save_values IP6T_block bool $2
			case "$?" in
				0)  IP6T_block=$2 ; shift ;;
				1)  IP6T_block=true ;;
				2)  IP6T_block=false ;;
			esac
			;;

		--vpn) # VPN
			save_values vpn bool $2
			case "$?" in
				0)  vpn=$2 ; shift ;;
				1)  vpn=true ;;
				2)  vpn=false ;;
			esac
			;;

		--strict) # 限制
			save_values strict bool $2
			case "$?" in
				0)  strict=$2 ; shift ;;
				1)  strict=true ;;
				2)  strict=false ;;
			esac
			;;

		*)
			echo "[Error]: Invalid argument: $1\n"
			usage 1
			;;

	esac
	shift
	done
}

# main
	. $MODDIR/lib.sh || { echo '[Error]: lib.sh not exist.'; exit 1; }
	. $SET_FILE || { echo '[Error]: script settings not exist.'; exit 1; }

	[ -z "$Listen_PORT" ] && { echo '[Error]: Listen_PORT not set.'; exit 1; }
	echo $mode |grep -q 'P' && [ -z "$Route_PORT" ] && { mode=${mode//P/}; echo '[Warning]: Route_PORT not set.'; }
	[ "$vpn" == 'true' ] && vpn='' || vpn='! -o tun+'

	if [ "${1}" == 'elf' ]; then
		shift
		$CORE_DIR/$CORE_BINARY $*
	elif [ "$1" == 'bin' ]; then
		shift
		$CORE_BOOT $*
	else
		if [ -z "$1" ]; then
			usage 0
		else
			get_args "$@"
		fi
	fi
