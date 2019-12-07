#!/system/bin/sh
MODDIR=/data/adb/modules/smartdns
[[ $# -eq 0 ]] && { echo "${MODDIR##\/*\/}: No command specified\nTry \'-usage\' for more information."; exit 2; }
[[ $(id -u) -ne 0 ]] && { echo "${MODDIR##\/*\/}: Permission denied"; exit 1; }

# 获取配置
source $MODDIR/constant.sh || exit 1

## 防火墙
# 主控
function iptrules_on()
{
	iptrules_load $IPT -I
	ip6trules_switch -I
}

function iptrules_off()
{
	i=0; while iptrules_check; do
		iptrules_load $IPT -D
		ip6trules_switch -D; ((++i))
		[[ $i > 5 ]] \
		&& { echo '(E) iptrules check error'; exit 1; }
	done
}

function ip6trules_switch()
{
	if $ipt_block_v6; then
		block_load $IP6T $1
	else
		iptrules_load $IP6T $1
	fi
}

# 加载
function iptrules_load()
{
	echo "(i) $1 $2"
	for IPP in $protocol
	do
		# DNS_LOCAL
		$1 -t nat $2 OUTPUT -p $IPP --dport 53 -j DNS_LOCAL
		$1 -t nat $2 POSTROUTING -p $IPP -d 127.0.0.1 --dport $LPORT -j SNAT --to-source 127.0.0.1
		# DNS_EXTERNAL
		$1 -t nat $2 PREROUTING -p $IPP --dport 53 -j REDIRECT --to-ports $LPORT
	done

	#Extra_rules
	$1 -t filter $2 INPUT -p tcp -m tcp --sport 80 --tcp-flags SYN,RST,URG FIN,PSH,ACK -m ttl --ttl-gt 20 -m ttl --ttl-lt 30 -j DROP
}

function block_load()
{
	$1 -t filter $2 OUTPUT -p udp --dport 53 -j DROP
	$1 -t filter $2 OUTPUT -p tcp --dport 53 -j REJECT --reject-with tcp-reset
}

# 初始化
function iptrules_set()
{
	echo "(i) $1 iptrules set"
	$1 -t nat -N DNS_LOCAL
	$1 -t nat -A DNS_LOCAL -m owner --uid-owner $(id -u $ServerUID) -j RETURN

	for IPP in 'udp' 'tcp'
	do
		$1 -t nat -A DNS_LOCAL -p $IPP -j REDIRECT --to-ports $LPORT
	done
}

# 清除规则
function iptrules_unset()
{
	echo "(i) $1 iptrules unset"
	$1 -t nat -F DNS_LOCAL
	$1 -t nat -X DNS_LOCAL
}



## 检查
# 防火墙
function iptrules_check()
{
	[ -n "`$IPT -t nat -S OUTPUT | grep 'DNS_LOCAL'`" ] && return 0 || return 1
}

# 核心进程
function core_check()
{
	[ -n "`pgrep $CORE_BINARY`" ] && return 0 || return 1
}



## 其他
# (重)启动核心
function core_start()
{
	core_check && killall $CORE_BINARY
	sleep 1
	#setuidgid UID GID GROUPS
	$CORE_DIR/setuidgid $(id -u $ServerUID) $(id -g $ServerUID) $(id -g $ServerUID),$(id -g inet),$(id -g media_rw) $CORE_BOOT 2>&1
	sleep 3
	if core_check; then
		echo "(i) Server start [$(date +'%d/%r')]"
		return 0
	else
		echo '(E) Server not working'
		exit 1
	fi
}



### 命令
case $1 in
	# 启动
	-start)
		iptrules_off
		if core_start; then
			iptrules_on
		fi
	;;
	# 停止
	-stop)
		iptrules_off
		killall $CORE_BINARY
		echo "(i) Server stop [$(date +'%d/%r')]"
	;;
	# 检查状态
	-status)
		i=0;
		core_check && { echo '< Server Online>'; }||{ echo '! Server Offline !'; i=`expr $i + 2`; }
		iptrules_check && { echo '< iprules On >'; }||{ echo '! iprules Off !'; ((++i)); }
	case $i in
	3)  # 未工作
	exit 11 ;;
	2)  # 核心
	exit 1 ;;
	1)  # 防火墙
	exit 10 ;;
	0)  # 工作中
	exit 0 ;;
	esac
	;;
	# 仅启动核心
	-start-core)
		core_start
	;;
	# 帮助信息
	-usage)
cat <<EOD
[command]
	-start
		Start Service
	-stop
		Stop Service
	-status
		Service Status
	-start-core
		Boot core only
	-iptrules-set
		Set iptables
	-iptrules-reset
		Reset iptables
EOD
	;;
####
	# 初始化规则
	-iptrules-set)
		iptrules_set $IPT
		if $ipt_block_v6; then
			iptrules_set $IP6T
		fi
	;;
	# 清空规则
	-iptrules-reset)
		iptrules_load $IPT -D
		ip6trules_switch -D

		iptrules_unset $IPT
		iptrules_unset $IP6T
		killall $CORE_BINARY
	;;
	# 命令传递
	*)
		$CORE_DIR/$CORE_BINARY $*
	;;
esac
exit 0
