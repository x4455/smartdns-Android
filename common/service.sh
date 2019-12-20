#!/system/bin/sh
MODDIR=${0%/*}
source $MODDIR/lib.sh

mkdir -p "$ROOT/log"
mkdir -p "$CORE_DIR"
mkdir -p "$DATA_DIR"

mount -o bind "$CORE_INTERNAL_DIR" "$CORE_DIR"
mount -o bind "$DATA_INTERNAL_DIR" "$DATA_DIR"

while [[ ! -d "/sdcard/Android" ]]
do
	sleep 1
done

LOG_PATH="$ROOT/log/boot.log"
[ -f $LOG_PATH ] && rm $LOG_PATH
exec 1>>$LOG_PATH 2>&1
set -x

/system/bin/sh $MODDIR/system/xbin/smartdns -start
sleep 5
cat $ROOT/log/smartdns.log

exit 0
