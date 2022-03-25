#!/system/bin/sh
#/data/adb/smartdns/scripts/bootTask/crond.sh
scripts_DIR=${0%/*/*}

#不存在则停止
if [ ! -f $scripts_DIR/cronTask/root ]; then
	echo 'File not found, timed task disabled'
	exit 0
else
	chmod 750 $scripts_DIR/cronTask/root
fi

if [ -f /data/adb/magisk/busybox ]; then
	alias crond="/data/adb/magisk/busybox crond"
elif [ -f /system/xbin/busybox ]; then
	alias crond="/system/xbin/busybox crond"
else
	exit 1
fi

if [ -z "$(pgrep -f "$scripts_DIR/cronTask")" ]; then
	pkill -9 -f "$scripts_DIR/cronTask"
	#crond -b -c $scripts_DIR/cronTask -L $scripts_DIR/crond.log
	crond -b -c $scripts_DIR/cronTask
	echo 'crond started'
else
	pkill -9 -f "$scripts_DIR/cronTask"
	echo 'crond stopped'
fi
exit $?
