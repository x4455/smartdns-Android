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
[ ! -d $WORK_DIR ] && initTask


### 加载函数 ###

## 防火墙部分
iptrules_on() {
	if [[ "$MODE" != *'local'* && "$MODE" != *'proxy'* ]]; then
		return 0
	fi
	local IPP
	#  IPv4
	# 建链 dns_redirect
	iptables -t nat -N dns_redirect
	# 加载重定向规则
	iptrules_load 'iptables' '-A'
	# 外链
	for IPP in $packet_type
	do
		iptables -t nat -A OUTPUT -p ${IPP} --dport 53 -j dns_redirect
		iptables -t nat -A POSTROUTING -p ${IPP} -m mark --mark 0x853 -j SNAT --to-source '127.0.0.1'
	done


	#  IPv6
	if [ "$IP6T_BLOCK" == 'yes' ]; then
		# 建链 dns_block
		ip6tables -t filter -N dns_block
		# 放行 PKG应用 IPv6 53
		iptrules_accept 'ip6tables' '-A' 'dns_block'
		# tun接口 放行
		[ "$TUN" == 'yes' ] && ip6tables -t filter -A dns_block -o tun+ -j RETURN
		# 封锁
		ip6tables -t filter -A dns_block -p udp -j DROP
		ip6tables -t filter -A dns_block -p tcp -j REJECT --reject-with tcp-reset
		# 进入链 dns_block
		for IPP in 'udp' 'tcp'
		do
			ip6tables -t filter -A OUTPUT -p ${IPP} --dport 53 -j dns_block
		done
	else
		# 建链 dns_redirect
		ip6tables -t nat -N dns_redirect
		# 加载重定向规则
		iptrules_load 'ip6tables' '-A'
		# 外链
		for IPP in $packet_type
		do
			ip6tables -t nat -A OUTPUT -p ${IPP} --dport 53 -j dns_redirect
			ip6tables -t nat -A POSTROUTING -p ${IPP} -m mark --mark 0x853 -j SNAT --to-source '::1'
		done
	fi
}



iptrules_off() {
	if [[ "$MODE" != *'local'* && "$MODE" != *'proxy'* ]]; then
		return 0
	fi
	local count='0' IPP
	while iptrules_check; do
		#  IPv4
		# 移除外链
		for IPP in $packet_type
		do
			iptables -t nat -D OUTPUT -p ${IPP} --dport 53 -j dns_redirect
			iptables -t nat -D POSTROUTING -p ${IPP} -m mark --mark 0x853 -j SNAT --to-source '127.0.0.1'
		done
		# 清空删除链
		iptables -t nat -F dns_redirect
		iptables -t nat -X dns_redirect


		#  IPv6
		if [ "$IP6T_BLOCK" == 'yes' ]; then
			# 封锁
			# 移除封锁引用
			for IPP in 'udp' 'tcp'
			do
				ip6tables -t filter -D OUTPUT -p ${IPP} --dport 53 -j dns_block
			done
			# 清空删除链
			ip6tables -t filter -F dns_block
			ip6tables -t filter -X dns_block
		else
			# 重定向
			# 移除外链
			for IPP in $packet_type
			do
				ip6tables -t nat -D OUTPUT -p ${IPP} --dport 53 -j dns_redirect
				ip6tables -t nat -D POSTROUTING -p ${IPP} -m mark --mark 0x853 -j SNAT --to-source '::1'
			done
			# 清空删除链
			ip6tables -t nat -F dns_redirect
			ip6tables -t nat -X dns_redirect
		fi
		# 防出错
		[ "${count}" -gt '3' ] && { print_iptRules_remove_errors; exit 1; } || let count++
	done
}



# 加载重定向规则
iptrules_load() {
	# [iptables/ip6tables]  [-A/-D]
	local ipt=${1} action=${2} IP IPP
	
	# LOCAL
	if [[ "$MODE" == *'local'* ]]; then
		# 特定UID 放行
		iptrules_accept ${ipt} ${action} 'dns_redirect'
		# tun接口 放行
		[ "$TUN" == 'yes' ] && ${ipt} -t nat ${action} dns_redirect -o tun+ -j RETURN
		# wlan接口 放行
		[ "$WLAN" == 'yes' ] && ${ipt} -t nat ${action} dns_redirect -o wlan+ -j RETURN
		# data接口 放行
		[ "$DATA" == 'yes' ] && ${ipt} -t nat ${action} dns_redirect -o rmnet_data+ -j RETURN
		for IPP in $packet_type
		do
			${ipt} -t nat ${action} dns_redirect -p ${IPP} -j MARK --set-xmark 0x853
			${ipt} -t nat ${action} dns_redirect -p ${IPP} -j REDIRECT --to-ports ${Main_PORT}
		done
	fi
	
	
	# PROXY
	if [[ "$MODE" == *'proxy'* ]]; then
		for IPP in $packet_type
		do
			if [ "$ipt" == 'iptables' ]; then
				# 获取本机IP
				IP=''; for IP in "$(ifconfig |grep "inet addr" |grep -v ":127" |grep "Bcast" |awk '{print $2}' |awk -F: '{print $2}')"
				do
					echo $IP |grep -q -E '(^192\.168\.*)|(^10\.*)|(^172\.(1[6-9]|2[0-9]|3[0-1])\.*)' || continue
					# v4 安全代理
					${ipt} -t nat ${action} PREROUTING -i wlan+ -p ${IPP} -d ${IP} --dport 53 -j REDIRECT --to-ports ${Second_PORT}
				done
			# else
			# v6 代理 停用
			#	${ipt} -t nat ${action} PREROUTING -p ${IPP} --dport 53 -j REDIRECT --to-ports ${Second_PORT}
			fi
		done
	fi
}



# 放行特定UID
	#[iptables/ip6tables]  (raw->mangle->nat->filter)  [-A/-D]  (udp/tcp)
	## dns_redirect 链
	# ${ipt} -t nat ${action} dns_redirect -m owner --uid-owner $uid -j RETURN
	## dns_block 链 (IPv6)
	# ${ipt} -t filter ${action} dns_block -m owner --uid-owner $uid -j RETURN
iptrules_accept() {
	[ -z "$PKG" ] && return 0
	local ipt=${1} action=${2}
	local tables chains uid
	case "${3}" in
		dns_block)
		tables='filter'; chains='dns_block';;
		dns_redirect)
		tables='nat'; chains='dns_redirect';;
	esac

	for uid in '0' '1001' $PKG
	do
		# 包名转换UID
		echo "$uid" |grep -q -i '[a-z]' && uid=$(grep -m1 -i $uid /data/system/packages.list |cut -d' ' -f2)
		# 不存在则跳过
		[ -z "$uid" ] && continue
		${ipt} -t ${tables} ${action} ${chains} -m owner --uid-owner ${uid} -j RETURN
	done
}





## 服务器部分

# 启动服务器
server_start() {
	# 常规启动
	PATH="$CORE_DIR:$PATH"
	$CORE_BOOT &
	PATH=${PATH#*:}
	# 启动检测
	local count='0' PID
	while true; do
		PID="$(pgrep $CORE_NAME)"
		# PID写入文件
		echo "$PID" > $PID_FILE
		if [ -n "$PID" ]; then
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
	local PID
	if [ -f "$PID_FILE" ]; then
		# 正常退出
		rm -f "$PID_FILE"
		for PID in $(pgrep $CORE_NAME)
		do
			kill -TERM "$PID"
			if [ "$?" != '0' ]; then
				print_server_stop_failed
				exit 1;
			fi
		done
		print_server_stop_success
	else
		# 强制退出
		for PID in $(pgrep $CORE_NAME)
		do
			kill -9 "$PID"
		done
		if [ -z "$PID" ]; then
			print_status_server_not_running
		else
			print_server_stop_success
		fi
	fi
}


## 状态部分
# 检查服务器状态
server_check() {
	local PID="$(pgrep $CORE_NAME)"
	if [ -z "$PID" ]; then
		[ -f "$PID_FILE" ] && rm -f "$PID_FILE"
		return 1
	fi
	# 修复PID文件
	[ ! -f "$PID_FILE" ] && echo "$PID" > $PID_FILE
	return 0
}

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

# 检查服务状态
service_check() {
	local count='0'
	# 服务器状态
	if server_check; then
		print_status_server_already_running
	else
		print_status_server_not_running; let count+=2
	fi
	# 防火墙规则状态
	if [[ "$MODE" == *'local'* ]] || [[ "$MODE" == *'proxy'* ]]; then
		local i='0'
		if [[ "$MODE" == *'local'* ]]; then
			iptables -t nat -S 2>/dev/null |grep -q -E "REDIRECT.+$Main_PORT" || { let i--; print_status_iptRules_Local_not_added; }
		fi
		if [[ "$MODE" == *'proxy'* ]]; then
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
save_values() {
	# $1(参数名) | $2(参数数值) | $3(为bool时，接受布尔值，没有则自行反转)
	local value_name="$1" value="$2" content
	content="$(grep "${value_name}=" $SCRIPT_CONF)"
	#更改前停止
	iptrules_check && iptrules_off
	server_check && server_stop

	#分离非布尔值
	if [ "$3" != 'bool' ]; then
		sed -i "s/^${content}/${value_name}=\'${value}\'/g" $SCRIPT_CONF
	else
		#判断是否布尔值
		if [ "${value}" == 'yes' -o "${value}" == 'no' ]; then
			sed -i "s/^${content}/${value_name}=\'${value}\'/g" $SCRIPT_CONF
		else
			#自行反转
			if [ "$(echo ${content} |awk -F "=" '{print $2}')" == 'yes' ]; then
				sed -i "s/^${content}/${value_name}=\'no\'/g" $SCRIPT_CONF
				return 2
			else
				sed -i "s/^${content}/${value_name}=\'yes\'/g" $SCRIPT_CONF
				return 1
			fi
		
		fi
	fi
	return 0
}

# 验证端口是否正确
port_valid() {
	# (^[1-9][0-9]{0,3}$)|(^[1-5]{0,1}[0-9]{3,4}$)|(^6[0-5]{2}[0-3][0-5]$)
	if echo "$1" |grep -q -E '^(?:[1-9]\d{0,3}|[1-5]\d{4}|6[0-4]\d{3}|65[0-4]\d{2}|655[0-2]\d|6553[0-5])$'; then
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
			# 还原 iptables
			# iptables -F
			# ip6tables -F
			iptables-restore < $IPT_BAK
			ip6tables-restore < $IP6T_BAK
			# 停止服务器
			server_stop
			server_stop  
			print_reset_network
			# 移除缓存持久化
			rm `awk '!/#/ && /cache-file/ {print $2}' $DATA_DIR/smartdns.conf` 2>/dev/null
			;;

		--mode) # 工作模式
			shift
			case "$1" in
				lo*pr*)
					save_values MODE 'local,proxy'
					MODE='local,proxy'
					;;
				lo*)
					save_values MODE 'local'
					MODE='local'
					;;
				pr*)
					save_values MODE 'proxy'
					MODE='proxy'
					;;
				ser*)
					save_values MODE 'server'
					MODE='server'
					;;
				*)
					print_invalid_value "$1"
					exit 1
					;;
			esac
			;;

		*) # 无效命令
			print_invalid_argument "$1"
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
	port_valid "$Second_PORT" || Second_PORT="$Main_PORT"
	# 未tcp端口设置 不使用tcp规则 # (?<!#\s*)bind-tcp.*\:+
	[ -n "`awk '!/#/ && /bind-tcp/' $DATA_DIR/smartdns.conf`" ] && readonly packet_type='udp tcp' || readonly packet_type='udp'
	# 检查IPv6 nat支持
	[ "$IP6T_BLOCK" == 'no' ] && { ip6tables -t nat -S >/dev/null 2>&1 || { print_kernel_not_support; IP6T_BLOCK='yes'; }; }

	if [ "${1}" == 'command' ]; then
		shift
		# 直接命令
		$CORE_DIR/$CORE_NAME "$@"
	elif [ "$1" == 'check' ]; then
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
