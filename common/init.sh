#!/system/bin/sh
MODDIR=${0%/*}
. $MODDIR/lib.sh || { echo "[Error]: service.sh can't load lib!" > $MODDIR/boot.log ; exit 1; }

LOG_PATH="$MODDIR/boot.log"
[ -f $LOG_PATH ] && rm $LOG_PATH
exec 1>>$LOG_PATH 2>&1
set -x

#路径
rm -r $DATA_INTERNAL_DIR/log
mkdir $DATA_INTERNAL_DIR/log
mkdir -p "$DATA_DIR"
mkdir -p "$CORE_DIR"
ln -fs $MODDIR/script.sh /sbin/smartdns
mount -o bind "$CORE_INTERNAL_DIR" "$CORE_DIR"
mount -o bind "$DATA_INTERNAL_DIR" "$DATA_DIR"

#权限
#chmod 0775 `find $DATA_DIR -type d`
#chmod 0664 `find $DATA_DIR -type f`
#chown -R $(id -u media_rw):$(id -u media_rw) $DATA_DIR

retry=0
while [ "$retry" -lt '9' ]
do
 ping -c 1 dns.google
 if [ "$?" == '0' ]; then
  break
 else
  let retry++
  sleep 10
 fi
done

iptables-save > $ROOT/iptables.origin
ip6tables-save > $ROOT/ip6tables.origin

#启动脚本
[ "$tools" == 'disable' ] || {
[ -z "$tools" ] && tools=`find $MODDIR/tools -maxdepth 1 -type f -name *'.sh'`
for file in ${tools##\/*\/}
do
 sh $MODDIR/tools/$file
 sleep 3
done
}

sh $MODDIR/script.sh -start

#cat $(grep "log-file " $DATA_DIR/smartdns.conf |awk -F " " '{print $2}')
exit 0