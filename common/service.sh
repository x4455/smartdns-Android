#!/system/bin/sh
MODDIR=${0%/*}
BOOT_LOG="$MODDIR/boot.log"
[ -f $BOOT_LOG ] && rm $BOOT_LOG
exec 1>>$BOOT_LOG 2>&1
set -x

nohup sh $MODDIR/init.sh &
