#!/system/bin/sh
# Script by x4455 @ github
MODDIR=${0%/*}
source $MODDIR/constant.sh

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

RETRY=10
until (("$RETRY" < "0")) || [ "`getprop init.svc.bootanim`" = "stopped" ]
do
 sleep 20
 ((RETRY--))
done
log

RETRY=5
until (("$RETRY" > "40"))
do
 ping -c 1 1.0.0.1
 if [ "$?" == '0' ]; then
   break
 else
   sleep $RETRY
   ((RETRY++))
 fi
done

echo "- Start : $(date +'%d / %r')"
/system/bin/sh /system/xbin/smartdns -start
echo "- End : $(date +'%d / %r')"

exit 0
