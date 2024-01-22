#!/system/bin/sh
# PATH
readonly WORK_DIR=/data/adb/smartdns/scripts/bootTask/crond
readonly TASK_DIR=/data/adb/smartdns/scripts/cronTask

if [ -f /data/adb/magisk/busybox ]; then
	alias crond="/data/adb/magisk/busybox crond"
elif [ -f /system/xbin/busybox ]; then
	alias crond="/system/xbin/busybox crond"
else
	exit 1
fi

cd $WORK_DIR

# 生成列表
if [ ! -d user ]; then
	mkdir user
fi
lists=`find $TASK_DIR -mindepth 2 -name 'crond.reg'`
[ -n "$lists" ] && {
	rm user/* 2>>crond.log
	for file in $lists; do
		grep -v '#' "$file" >> user/root
	done
	chmod 0750 user/root
}

# 启动 crond
pkill -9 -f "$WORK_DIR/user"
crond -b -c $WORK_DIR/user -L crond.log

exit