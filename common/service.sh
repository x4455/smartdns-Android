#!/system/bin/sh
MODDIR=${0%/*}
LOG_PATH="$MODDIR/boot.log"
[ -f $LOG_PATH ] && rm $LOG_PATH
exec 1>>$LOG_PATH 2>&1
set -x

nohup sh $MODDIR/init.sh &
