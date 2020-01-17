#!/system/bin/sh
MODDIR=${0%/*}
. $MODDIR/lib.sh || { echo "Error: service.sh can't load lib!" > $MODDIR/boot.log ; exit 1; }

LOG_PATH="$ROOT/log/boot.log"
[ -f $LOG_PATH ] && rm $LOG_PATH
exec 1>>$LOG_PATH 2>&1
set -x

while [[ ! -d "/sdcard/Android" ]]
do
	sleep 10
done

/system/bin/sh $MODDIR/system/xbin/smartdns -start
sleep 7
cat $(grep "log-file " $DATA_DIR/smartdns.conf | awk -F " " '{print $2}')

exit 0
