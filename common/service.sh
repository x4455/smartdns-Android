#!/system/bin/sh
MODDIR=${0%/*}
. $MODDIR/lib.sh || { echo "[Error]: service.sh can't load lib!" > $MODDIR/boot.log ; exit 1; }

LOG_PATH="$MODDIR/boot.log"
[ -f $LOG_PATH ] && rm $LOG_PATH
exec 1>>$LOG_PATH 2>&1
set -x

[ -d $DATA_INTERNAL_DIR/log ] && rm $DATA_INTERNAL_DIR/log/* || mkdir $DATA_INTERNAL_DIR/log
mkdir -p "$DATA_DIR"
mkdir -p "$CORE_DIR"
ln -fs $MODDIR/script.sh /sbin/smartdns
mount -o bind "$CORE_INTERNAL_DIR" "$CORE_DIR"
mount -o bind "$DATA_INTERNAL_DIR" "$DATA_DIR"

chmod 0774 `find $DATA_DIR -type d`
chmod 0664 `find $DATA_DIR -type f`
chown -R media_rw:media_rw $DATA_DIR

retry=0
while [ "$retry" -lt '20' ]
do
 ping -c 1 google.cn
 if [ "$?" == '0' ]; then
  break
 else
  let retry++
  sleep 10
 fi
done

iptables-save > $ROOT/iptables.origin
ip6tables-save > $ROOT/ip6tables.origin

sh $MODDIR/script.sh -start

sleep 5
#[ -z $script ] && script=$(ls $MODDIR/tools | grep '.sh')
#for file in $script
#do
# sh $file 2>&1 >/dev/null
#done
cat $(grep "log-file " $DATA_DIR/smartdns.conf | awk -F " " '{print $2}')
exit 0
