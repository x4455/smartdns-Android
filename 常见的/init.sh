#!/system/bin/sh
MODDIR=${0%/*}
. $MODDIR/lib.sh

if [ "$log" == "true" ]; then
BOOT_LOG="$MODDIR/boot.log"
exec 1>>$BOOT_LOG 2>&1
set -x
fi

#创建工作环境
rm -r $DATA_INTERNAL_DIR/log
mkdir $DATA_INTERNAL_DIR/log
mkdir -p "$DATA_DIR"
mkdir -p "$CORE_DIR"
ln -fs $MODDIR/script.sh /system/bin/smartdns
mount -o bind "$CORE_INTERNAL_DIR" "$CORE_DIR"
mount -o bind "$DATA_INTERNAL_DIR" "$DATA_DIR"

#等候网络连接
wait_count=0; while true; do
	ping -c 1 dns.google
	if [ "$?" == '0' ]; then
		break
	elif [ ${wait_count} -ge 40 ] ; then
		exit 0
	else
		wait_count=$((${wait_count} + 1)); sleep 20
	fi
done

#保存防火墙初始设置
iptables-save > $ROOT/iptables.origin
ip6tables-save > $ROOT/ip6tables.origin

#启动插件脚本
tools=`find $MODDIR/tools -maxdepth 1 -type l -name '*.init'`
[ -n "$tools" ] && {
for file in $tools; do
	sh $file
	sleep 3
done
}
#启动主服务
sh $MODDIR/script.sh start

#cat $(grep "log-file " $DATA_DIR/smartdns.conf |awk -F " " '{print $2}')
exit 0
