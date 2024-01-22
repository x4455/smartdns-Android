#!/system/bin/sh
MODDIR=${0%/*}
cd $MODDIR
. $MODDIR/constant.sh

# 日志清理
rm $BOOT_LOG $RUN_LOG $CROND_LOG

# 日志生成
. $SCRIPT_CONF
if [ "$log" == "yes" ]; then
	[ -f $BOOT_LOG ] && rm $BOOT_LOG
	exec 1>>$BOOT_LOG 2>&1
	set -x
fi

# 启动服务
sh command.sh start

exit