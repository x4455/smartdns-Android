#!/system/bin/sh
MODDIR=${0%/*}
LOG_PATH="$MODDIR/boot.log"
#[ -f $LOG_PATH ] && rm $LOG_PATH
exec 1>>$LOG_PATH 2>&1
set -x

. $MODDIR/lib.sh

#路径
rm -r $DATA_INTERNAL_DIR/log
mkdir $DATA_INTERNAL_DIR/log
mkdir -p "$DATA_DIR"
mkdir -p "$CORE_DIR"
ln -fs $MODDIR/script.sh /sbin/smartdns
mount -o bind "$CORE_INTERNAL_DIR" "$CORE_DIR"
mount -o bind "$DATA_INTERNAL_DIR" "$DATA_DIR"

while true; do
 ping -c 1 dns.google
 if [ "$?" == '0' ]; then
  break
 else
  sleep 20
 fi
done

#初始配置
iptables-save > $ROOT/iptables.origin
ip6tables-save > $ROOT/ip6tables.origin

#启动脚本
tools=`find $MODDIR/tools -maxdepth 1 -type f -name *'.sh'`
[ -n "$tools" ] && {
for file in $tools
do
 sh $file
 sleep 3
done
}

sh $MODDIR/script.sh -start

#cat $(grep "log-file " $DATA_DIR/smartdns.conf |awk -F " " '{print $2}')
exit 0