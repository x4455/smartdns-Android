#!/system/bin/sh
# Script by x4455 @ github
MODDIR=${0%/*}
source $MODDIR/constant.sh

while [[ ! -d "/sdcard/Android" ]]
do
  sleep 1
done

LOG_PATH="$MODDIR/boot.log"
[ -f $LOG_PATH ] \
  && rm $LOG_PATH
exec 1>>$LOG_PATH 2>&1
set -x

echo "- Start : $(date +'%d / %r')"

/system/bin/sh $MODDIR/system/xbin/smartdns -set

/system/bin/sh $MODDIR/system/xbin/smartdns -start

exit 0
