#!/system/bin/sh
MODDIR=${0%/*}
. $MODDIR/lib.sh || { echo "Error: service.sh can't load lib!" > $MODDIR/boot.log ; exit 1; }

LOG_PATH="$MODDIR/boot.log"
[ -f $LOG_PATH ] && rm $LOG_PATH
exec 1>>$LOG_PATH 2>&1
set -x

mkdir -p "$ROOT/log"
mkdir -p "$CORE_DIR"
mkdir -p "$DATA_DIR"
ln -fs $MODDIR/script.sh /sbin/smartdns
mount -o bind "$CORE_INTERNAL_DIR" "$CORE_DIR"
mount -o bind "$DATA_INTERNAL_DIR" "$DATA_DIR"

while [[ ! -d "/sdcard/Android" ]]
do
	sleep 5
done

sh $MODDIR/script.sh -start
sleep 7
cat $(grep "log-file " $DATA_DIR/smartdns.conf | awk -F " " '{print $2}')

exit 0
