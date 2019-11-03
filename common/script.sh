#!/system/bin/sh

[[ "$#" -eq 0 ]] && { echo "script: no command specified\nTry \'-usage\' for more information."; exit 2; }
[[ $(id -u) -ne 0 ]] && { echo "script: permission denied"; exit 1; }

LPORT=6453
ipt_block_v6=true

# 获取配置
MODDIR="/data/adb/modules/smartdns"
source $MODDIR/constant.sh

ServerGID="`id -g $ServerUID`"
ServerGROUPS="$ServerGID,$(id -g inet),$(id -g media_rw)"
ServerUID="`id -u $ServerUID`"

## 防火墙
# 主控
function iptrules_on()
{
	iptrules_load $IPT -I
	ip6trules_load -A
}

function iptrules_off()
{
	while iptrules_check; do
		iptrules_load $IPT -D
		ip6trules_load -D
	done
}

function ip6trules_load()
{
	if [ "$ipt_block_v6" == 'true' ]; then
		block_load $IP6T $1 OUTPUT
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
		$1 -t nat $2 OUTPUT -p $IPP --dport 53 -j DNS_LOCAL
		$1 -t nat $2 PREROUTING -p $IPP --dport 53 -j DNS_EXTERNAL
	done
}

function block_load()
{
	$1 -t filter $2 $3 -p udp --dport 53 -j DROP
	$1 -t filter $2 $3 -p tcp --dport 53 -j REJECT --reject-with tcp-reset
}

# 初始化
function iptrules_set()
{
	echo "(i) $1 iptrules set"
	$1 -t nat -N DNS_LOCAL
	$1 -t nat -N DNS_EXTERNAL

	$1 -t nat -A DNS_LOCAL -m owner --uid-owner $ServerUID -j RETURN
	for IPP in 'udp' 'tcp'
	do
		$1 -t nat -A DNS_LOCAL -p $IPP -j REDIRECT --to-ports $LPORT

		$1 -t nat -A DNS_EXTERNAL -p $IPP -j REDIRECT --to-ports $LPORT
	done
}

# 清除规则
function iptrules_reset()
{
	echo "(i) $1 iptrules reset"
	$1 -t nat -F DNS_LOCAL
	$1 -t nat -X DNS_LOCAL

	$1 -t nat -F DNS_EXTERNAL
	$1 -t nat -X DNS_EXTERNAL
}



## 检查
# 防火墙规则
function iptrules_check()
{
	[ -n "`$IPT -n -t nat -L OUTPUT | grep "DNS_LOCAL"`" ] && return 0
}

# 核心进程
function core_check()
{
	[ -n "`pgrep $CORE_BINARY`" ] && return 0
}



## 其他
# (重)启动核心
function core_start()
{
	core_check && killall $CORE_BINARY
	sleep 1
	$CORE_DIR/setuidgid $ServerUID $ServerGID $ServerGROUPS $CORE_BOOT 2>&1
	sleep 1
	if [ ! core_check ]; then
		echo '(!) ERROR: Server not working'
		exit 1
	else
		echo "(i) Start [$(date +'%d/%r')]"
		return 0
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
	;;
	# 检查状态
	-status)
		i=0;
		core_check && { echo '< Server >'; }||{ echo '! Server Offline !'; i=`expr $i + 2`; }
		iptrules_check && { echo '< iprules >'; }||{ echo '! iprules Disabled !'; i=`expr $i + 1`; }
	case $i in
	3)  # 未工作
	exit 11 ;;
	2)  # 核心
	exit 01 ;;
	1)  # 防火墙
	exit 10 ;;
	0)  # 工作中
	exit 00 ;;
	esac
	;;
	# 仅启动核心
	-start-core)
		core_start
	;;
	# 帮助信息
	-usage)
cat <<EOD
Usage:
 -start
   Start Service
 -stop
   Stop Service
 -status
   Service Status
 -start-core
   Boot core only
 -set
   Set up iptables
 -reset
   Reset iptables
EOD
	;;
####
	# 初始化规则
	-set)
		iptrules_set $IPT
		if [ "$ipt_block_v6" == 'false' ]; then
			iptrules_set $IP6T
		fi
	;;
	# 清空规则
	-reset)
		iptrules_load $IPT -D
		ip6trules_load -D OUTPUT

		iptrules_reset $IPT
		iptrules_reset $IP6T
		killall $CORE_BINARY
	;;
	# 命令透传
	*)
		$CORE_PATH $*
	;;
esac
exit 0
