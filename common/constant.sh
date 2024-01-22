#!/system/bin/sh
### Program ###
readonly CORE_NAME="smartdns"

# PATH
#存储位置
readonly CORE_INTERNAL_DIR="$MODDIR/binary"
readonly DATA_INTERNAL_DIR="/data/adb/$CORE_NAME/config"
readonly SCRIPT_INTERNAL_DIR="/data/adb/$CORE_NAME/scripts"

#自启动日志
BOOT_LOG="$MODDIR/boot.log"
#脚本运行日志
RUN_LOG="$MODDIR/script.log"
#crontab日志
readonly CROND_LOG="$SCRIPT_INTERNAL_DIR/bootTask/crond/crond.log"

#脚本配置
readonly SCRIPT_CONF="$DATA_INTERNAL_DIR/script_conf.sh"


#工作目录
# /dev/$CORE_NAME
# ├─ /binary 程序
# ├─ /config 配置
# ├─ /log 日志
# └─ /tmp 暂存
readonly WORK_DIR="/dev/$CORE_NAME"
readonly CORE_DIR="$WORK_DIR/binary"
readonly DATA_DIR="$WORK_DIR/config"
LOG_DIR="$WORK_DIR/log"
TEMP_DIR="$WORK_DIR/tmp"

# 初始化
initTask() {
	# 创建工作环境
	mkdir -p "$CORE_DIR"
	mkdir -p "$DATA_DIR"
	mkdir -p "$LOG_DIR"
	mkdir -p "$TEMP_DIR"
	mount -o bind "$CORE_INTERNAL_DIR" "$CORE_DIR"
	mount -o bind "$DATA_INTERNAL_DIR" "$DATA_DIR"
	# 等候网络连接
	local count='0'
	while true; do
		ping -c 1 dns.google
		if [ "$?" == '0' ]; then
			break
		elif [ ${count} -ge 60 ] ; then
			break
		else
			sleep 10; count=$((${count} + 1));
		fi
	done
	# 保存防火墙初始设置
	iptables-save > $IPT_BAK
	ip6tables-save > $IP6T_BAK
	chmod 0640 $TEMP_DIR/*.bak
	bootTask
}

# 开机任务
bootTask() {
	local lists file
	lists=`find $SCRIPT_INTERNAL_DIR/bootTask -mindepth 2 -name 'boot.sh'`
	if [ -n "$lists" ]; then
		for file in $lists; do
			sh $file
			sleep 5
		done
	fi
}

#防火墙备份
readonly IPT_BAK="$TEMP_DIR/iptables_rules.bak"
readonly IP6T_BAK="$TEMP_DIR/ip6tables_rules.bak"

#程序PID
readonly PID_FILE="$TEMP_DIR/server.pid"

### 启动参数 ###
readonly CORE_BOOT="$CORE_NAME -c $DATA_DIR/smartdns.conf -p $PID_FILE"
