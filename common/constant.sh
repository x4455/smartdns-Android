#!/system/bin/sh
# Don't modify it. # Don't modify it. # Don't modify it.
#程序名
readonly CORE_NAME="smartdns"

### PATH ###
#自启动日志
BOOT_LOG="$MODDIR/boot.log"
#脚本运行日志
RUN_LOG="$MODDIR/script.log"


#存储位置
readonly CORE_INTERNAL_DIR="$MODDIR/binary"
readonly DATA_INTERNAL_DIR="/data/adb/$CORE_NAME/config"
readonly SCRIPT_INTERNAL_DIR="/data/adb/$CORE_NAME/scripts"
#脚本配置
readonly SCRIPT_CONF="$DATA_INTERNAL_DIR/script_conf.sh"


#运行环境
# /dev/smartdns
# ├─ /binary 程序
# ├─ /config 配置
# ├─ /log 日志
# └─ /tmp 暂存
initTask() {
	# 创建工作环境
	#mkdir -p "$DATA_DIR"
	#mkdir -p "$CORE_DIR"
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
}
readonly ROOT="/dev/$CORE_NAME"
readonly CORE_DIR="$ROOT/binary"
readonly DATA_DIR="$ROOT/config"
readonly LOG_DIR="$ROOT/log"
readonly TEMP_DIR="$ROOT/tmp"
#防火墙备份
readonly IPT_BAK="$TEMP_DIR/iptables_rules.bak"
readonly IP6T_BAK="$TEMP_DIR/ip6tables_rules.bak"
#程序PID
readonly PID_FILE="$TEMP_DIR/server.pid"


# 启动参数
readonly CORE_BOOT="$CORE_NAME -c $DATA_DIR/smartdns.conf -p $PID_FILE"
# 启动方式
boot_setuidgid() {
	# setuidgid 启动
	cd $CORE_DIR
	# setuidgid [$UID(root/radio) $UID $UID,inet,media_rw] command
	./setuidgid "$(id -u $ServerUID)" "$(id -g $ServerUID)" "$(id -g $ServerUID),$(id -g inet)" $CORE_BOOT &
	cd - 1>/dev/null
}
boot_server() {
	# 常规启动
	PATH="$CORE_DIR:$PATH"
	$CORE_BOOT &
	PATH=${PATH#*:}
}