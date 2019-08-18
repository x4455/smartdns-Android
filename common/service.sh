#!/system/bin/sh
# Script by x4455 @ github
MODDIR=${0%/*}
retry=6
source $MODDIR/constant.sh

until (("$retry" < "0")) || [ "`getprop init.svc.bootanim`" = "stopped" ]
do
 sleep 12
 ((retry--))
done

log() {
LOG_PATH="$MODDIR/boot.log"
[ -f $LOG_PATH ] \
  && rm $LOG_PATH
exec 1>>$LOG_PATH 2>&1
set -x
}
for TARGET in $ClearList
do
  rm $MODDIR/$TARGET
done
log

echo "Start - $(date +'%d / %r')"
/system/bin/sh /system/xbin/smartdns -start
echo "End - $(date +'%d / %r')"
exit 0
