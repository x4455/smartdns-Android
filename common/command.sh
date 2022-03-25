#!/system/bin/sh
# 获取真实路径
MODDIR=$(realpath $0)
MODDIR=${MODDIR%/*} ; cd $MODDIR
# 加载参数
. $MODDIR/constant.sh
. $MODDIR/defaults.sh
# 用户设置
. $SCRIPT_CONF
# 加载语言
if [ -f $MODDIR/translations/$language.sh ]; then
	. $MODDIR/translations/$language.sh
else
	. $MODDIR/translations/en.sh
fi
# 自动初始化
[ ! -d $ROOT ] && initTask


### 加载函数 ###


## 防火墙部分
iptrules_on() {
	if ! echo $MODE |grep -q -E '(L|P)'; then
		return 0
	fi
	local IPP
	#  IPv4
	# 建链 smartdns
	iptables -t nat -N smartdns
	# 加载重定向规则
	iptrules_load 'iptables' '-A'
	# 非指定UID数据包 引用 smartdns
	for IPP in $packet_type
	do
		iptables -t nat -A OUTPUT -p ${IPP} --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j smartdns
	done


	#  IPv6
	if [ "$IP6T_BLOCK" == 'yes' ]; then
		# 建链 dns_block
		ip6tables -t filter -N dns_block
		# 放行 PKG应用 IPv6 53数据包 
		rules_accept 'ip6tables' '-A' 'dns_block'
		# tun接口 放行
		[ "$TUN" == 'yes' ] && ip6tables -t filter -A dns_block -o tun+ -j RETURN
		# 封锁数据包
		ip6tables -t filter -A dns_block -p udp -j DROP
		ip6tables -t filter -A dns_block -p tcp -j REJECT --reject-with tcp-reset
		# 进入链 dns_block
		for IPP in 'udp' 'tcp'
		do
			ip6tables -t filter -A OUTPUT -p ${IPP} --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j dns_block
		done
	else
		# 建链 smartdns
		ip6tables -t nat -N smartdns
		# 加载重定向规则
		iptrules_load 'ip6tables' '-A'
		# 非指定UID数据包 引用 smartdns
		for IPP in $packet_type
		do
			ip6tables -t nat -A OUTPUT -p ${IPP} --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j smartdns
		done
	fi
}



iptrules_off() {
	if ! echo $MODE |grep -q -E '(L|P)'; then
		return 0
	fi
	local count='0' IPP
	while iptrules_check; do
		#  IPv4
		# 移除引用
		for IPP in $packet_type
		do
			iptables -t nat -D OUTPUT -p ${IPP} --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j smartdns
		done
		# 清空删除链
		iptables -t nat -F smartdns
		iptables -t nat -X smartdns


		#  IPv6
		if [ "$IP6T_BLOCK" == 'yes' ]; then
			# 移除封锁引用
			for IPP in 'udp' 'tcp'
			do
				ip6tables -t filter -D OUTPUT -p ${IPP} --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j dns_block
			done
			# 清空删除链
			ip6tables -t filter -F dns_block
			ip6tables -t filter -X dns_block
		else
			# 移除重定向引用
			for IPP in $packet_type
			do
				ip6tables -t nat -D OUTPUT -p ${IPP} --dport 53 -m owner ! --uid-owner $(id -u $ServerUID) -j smartdns
			done
			# 清空删除链
			ip6tables -t nat -F smartdns
			ip6tables -t nat -X smartdns
		fi
		# 防出错
		[[ ${count} > 3 ]] && { print_iptRules_remove_errors; exit 1; } || let count++
	done
}



# 加载重定向规则
iptrules_load() {
	# [iptables/ip6tables]  [-A/-D]
	local ipt=${1} action=${2}
	echo "[Info]: ${ipt##\/*\/} $action"
	local IP IPP
	
	# LOCAL
	if echo $MODE |grep -q 'L'; then
		# 特定UID 放行
		rules_accept ${ipt} ${action} 'smartdns'
		# tun接口 放行
		[ "$TUN" == 'yes' ] && ${ipt} -t nat ${action} smartdns -o tun+ -j RETURN
		# wlan接口 放行
		[ "$WLAN" == 'yes' ] && ${ipt} -t nat ${action} smartdns -o wlan+ -j RETURN
		# data接口 放行
		[ "$DATA" == 'yes' ] && ${ipt} -t nat ${action} smartdns -o rmnet_data+ -j RETURN
		for IPP in $packet_type
		do
			${ipt} -t nat ${action} smartdns -p ${IPP} -j MARK --set-xmark 0x853
			${ipt} -t nat ${action} smartdns -p ${IPP} -j REDIRECT --to-ports ${Main_PORT}
			# v4/v6
			[ "$ipt" == 'iptables' ] && IP='127.0.0.1' || IP='::1'
			${ipt} -t nat ${action} POSTROUTING -p ${IPP} -m mark --mark 0x853 -j SNAT --to-source ${IP}
		done
	fi
	
	
	# EXTERNAL
	if echo $MODE |grep -q 'P'; then
		for IPP in $packet_type
		do
			if [ "$ipt" == 'iptables' ]; then
				# 获取本机IP
				IP=''; for IP in "$(ifconfig |grep "inet addr" |grep -v ":127" |grep "Bcast" |awk '{print $2}' |awk -F: '{print $2}')"
				do
					# 不是私有IP跳过创建接收重定向 (rfc1918 过滤) 强制启用这个功能
					if [ "$STRICT" == 'yes' ]; then
						echo $IP |grep -q -E '(^192\.168\.*)|(^10\.*)|(^172\.(1[6-9]|2[0-9]|3[0-1])\.*)' || continue
						# v4 安全代理
						${ipt} -t nat ${action} PREROUTING -i wlan+ -p ${IPP} -d ${IP} --dport 53 -j REDIRECT --to-ports ${Second_PORT}
					else
						# v4 代理
						${ipt} -t nat ${action} PREROUTING -p ${IPP} -d ${IP} --dport 53 -j REDIRECT --to-ports ${Second_PORT}
					fi
				done
			fi
			# else
			# v6 代理 停用
			#	${ipt} -t nat ${action} PREROUTING -p ${IPP} --dport 53 -j REDIRECT --to-ports ${Second_PORT}
			# fi
		done
	fi
}



# 放行特定UID
	#[iptables/ip6tables]  (raw->mangle->nat->filter)  [-A/-D]  (udp/tcp)
	## smartdns 链
	# ${ipt} -t nat ${action} smartdns -m owner --uid-owner $uid -j RETURN
	## dns_block 链 (IPv6)
	# ${ipt} -t filter ${action} dns_block -m owner --uid-owner $uid -j RETURN
rules_accept() {
	[ -z "$PKG" ] && return 0
	local ipt=${1} action=${2}
	local tables chains uid
	case "${3}" in
		dns_block)
		tables='filter'; chains='dns_block';;
		smartdns)
		tables='nat'; chains='smartdns';;
	esac

	for uid in $PKG
	do
		echo $uid |grep -q -i '[a-z]' && uid=$(grep -m1 -i $uid /data/system/packages.list |cut -d' ' -f2)
		[ -z "$uid" ] && continue
		${ipt} -t ${tables} ${action} ${chains} -m owner --uid-owner ${uid} -j RETURN
	done
}





## 服务器部分
# 启动服务器
server_start() {
	boot_server
	local count='0' PID
	while true; do
		PID="$(cat $PID_FILE 2>/dev/null)"
		if [ -n "$PID" -a -e "/proc/$PID" ]; then
			print_server_start_success
			break
		elif [ ${count} -ge 30 ] ; then
			print_server_start_failed
			exit 1
		else
			sleep .5; count=$((${count} + 1))
		fi
	done
}

# 停止服务器
server_stop() {
	if [ ! -f "$PID_FILE" ]; then
		print_server_stop_stopped
		return 0
	fi
	PID="$(cat $PID_FILE 2>/dev/null)"
	if [ ! -e "/proc/$PID" -o -z "$PID" ]; then
		print_server_stop_stopped
		return 0
	fi

	kill -TERM "$PID"
	if [ $? -ne 0 ]; then
		print_server_stop_failed
		exit 1;
	fi
	rm -f "$PID_FILE"
	print_server_stop_success
}


## 状态数据包部分
# 检查防火墙状态
iptrules_check() {
if [ "$IP6T_BLOCK" == 'yes' ]; then
	if iptables -t nat -S 2>/dev/null |grep -q -E "REDIRECT.+($Main_PORT|$Second_PORT)$" ; then
		return 0
	else
		return 1
	fi
else
	if iptables -t nat -S 2>/dev/null |grep -q -E "REDIRECT.+($Main_PORT|$Second_PORT)$" \
	|| ip6tables -t nat -S 2>/dev/null |grep -q -E "REDIRECT.+($Main_PORT|$Second_PORT)$"; then
		return 0
	else
		return 1
	fi
fi
#iptables -t nat -nL PREROUTING 2>/dev/null | grep REDIRECT | grep dpt:53 | grep %q >/dev/null 2>&1
#ip6tables -t nat -nL PREROUTING 2>/dev/null | grep REDIRECT | grep dpt:53 | grep %q >/dev/null 2>&1
}

# 检查服务器状态
server_check() {
	if [ ! -f "$PID_FILE" ]; then
		return 1
	fi
	PID="$(cat $PID_FILE 2>/dev/null)"
	if [ ! -e "/proc/$PID" ] || [ -z "$PID" ]; then
		return 1
	fi
	return 0
}

# 检查服务状态
service_check() {
	local count='0' i='0'
	# 服务器状态
	server_check && { print_status_server_already_running; } || { print_status_server_not_running; let count+=2; } ####
	# 防火墙规则状态
	if [ -n "$MODE" ]; then
		if echo $MODE |grep -q 'L'; then
			iptables -t nat -S 2>/dev/null |grep -q -E "REDIRECT.+$Main_PORT" || { let i--; print_status_iptRules_Local_not_added; }
		fi
		if echo $MODE |grep -q 'P'; then
			iptables -t nat -S 2>/dev/null |grep -q -E "REDIRECT.+$Second_PORT" || { let i--; print_status_iptRules_Proxy_not_added; }
		fi
		if [ "$i" -eq 0 ]; then
			print_status_iptRules_added
		else
			let count++
		fi
	fi
	# 返回状态值
	case $count in
		3)   # 未启动
			return 3 ;;
		1|2) # 非正常工作状态
			return 1 ;;
		0)   # 正常工作
			return 0 ;;
	esac
}


## 其他部分
# 保存数值
save_values() {  # $1(将被修改的参数) $2(bool / 其他值) $3(当$2为bool时，接受布尔值，没有则自行反转)
	local value_name=$1 type=$2 value=$3
	#更改前自动停止
	iptrules_check && iptrules_off ; server_check && server_stop
	local content=$(grep "${value_name}=" $SCRIPT_CONF)
	#分离非布尔值
	if [ "${type}" != 'bool' ]; then
		sed -i "s/^${content}/${value_name}=\'${value}\'/g" $SCRIPT_CONF
	else
		#判断是否有指定值
		if [ "${value}" == 'yes' -o "${value}" == 'no' ]; then
			sed -i "s/^${content}/${value_name}=${value}/g" $SCRIPT_CONF
		#如为下一个命令或没有，自行反转
		elif [[ "${value}" == st* || "${value}" == -* || -z "${value}" ]]; then
			if [ "$(echo ${content} |awk -F "=" '{print $2}')" == 'yes' ]; then
				sed -i "s/^${content}/${value_name}=no/g" $SCRIPT_CONF
				return 2
			else
				sed -i "s/^${content}/${value_name}=yes/g" $SCRIPT_CONF
				return 1
			fi
		else
			print_invalid_value $value
			exit 1
		fi
	fi
	return 0
}

# 验证端口是否正确
port_valid() {
	if echo $1 |grep -q -E '(^[1-9][0-9]{0,3}$)|(^[1-5]{0,1}[0-9]{3,4}$)|(^6[0-5]{2}[0-3][0-5]$)'; then
		return 0
	else
		return 1
	fi
}

### 命令选项 ###

get_args() {
	while [ ${#} -gt 0 ]; do
	case "$1" in
		-h|--help) # 帮助信息
			print_help 0
			;;

		start) # 启动
			server_stop
			iptrules_off
			server_start && iptrules_on
			;;

		stop) # 停止
			iptrules_off
			server_stop
			;;

		status) # 检查状态
			service_check
			exit $?
			;;

		clean) # 清除
			# iptables -F
			# ip6tables -F
			iptables-restore < $IPT_BAK
			ip6tables-restore < $IP6T_BAK
			server_stop
			print_reset_network
			;;

		--bootTask) # 执行启动脚本
			local lists file
			lists=`find $SCRIPT_INTERNAL_DIR/bootTask -maxdepth 1 -name '*.sh'`
			[ -n "$lists" ] && {
				for file in $lists; do
					sh $file
					sleep 5
				done
			}
			;;

		-m|--mode) # 工作模式
			case "$2" in
				'local')
					save_values MODE 'L'
					MODE='L'
					;;
				'proxy')
					save_values MODE 'LP'
					MODE='LP'
					;;
				'server')
					save_values MODE ''
					MODE=''
					;;
				*)
					print_invalid_value $2
					exit 1
					;;
			esac
			shift
			;;

		# --interface) # [ tun / wlan / data ] ( yes/no )
		# 	case "$2" in
		# 		tun) # VPN
		# 			save_values TUN bool $3
		# 			case "$?" in
		# 				0)  TUN=$3 ; shift ;;
		# 				1)  TUN=yes ;;
		# 				2)  TUN=no ;;
		# 			esac
		# 			;;
		# 		wlan) # WiFi
		# 			save_values WLAN bool $3
		# 			case "$?" in
		# 				0)  WLAN=$3 ; shift ;;
		# 				1)  WLAN=yes ;;
		# 				2)  WLAN=no ;;
		# 			esac
		# 			;;
		# 		data) # Data
		# 			save_values DATA bool $3
		# 			case "$?" in
		# 				0)  DATA=$3 ; shift ;;
		# 				1)  DATA=yes ;;
		# 				2)  DATA=no ;;
		# 			esac
		# 			;;
		# 		*)
		# 			print_invalid_value $2
		# 			exit 1
		# 			;;
		# 	esac
		# 	shift
		# 	;;

		*) # 无有效命令
			print_invalid_argument $1
			print_help 1
			;;
	esac
	shift
	done
}



# main
	# 生成日志
	if [ "$log" == 'yes' ]; then
		echo -e "\nDate: $(date +%c)\ncommand: $*\n" >> $RUN_LOG
		exec 1>>$RUN_LOG 2>&1
		set -ex
	fi

	# 未设置主端口 停止
	port_valid "$Main_PORT" || { echo '[Error]: Main_PORT not set.'; exit 1; }
	# 未设置代理端口 使用主端口
	port_valid "$Second_PORT" || Second_PORT=$Main_PORT
	# 未tcp端口设置 不使用tcp规则 # (?<!#\s*)bind-tcp.*\:+
	[ -n "`awk '!/#/ && /bind-tcp/' $DATA_DIR/smartdns.conf`" ] && readonly packet_type='udp tcp' || readonly packet_type='udp'
	# 检查IPv6 nat支持
	[ $IP6T_BLOCK == 'no' ] && { ip6tables -t nat -S >/dev/null 2>&1 || { print_kernel_not_support; IP6T_BLOCK=yes; }; }

	if [ "${1}" == 'elf' ]; then
		shift
		# 直接命令smartdns
		$CORE_DIR/$CORE_NAME "$@"
	elif [ "$1" == 'elfwc' ]; then
		shift
		# 带配置命令
		$CORE_BOOT "$@"
	else
		if [ -z "$1" ]; then
			print_help 0
		else
			get_args "$@"
		fi
	fi
