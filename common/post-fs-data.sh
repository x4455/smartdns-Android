#!/system/bin/sh
MODDIR=${0%/*}
. $MODDIR/lib.sh || { echo "Error: post-fs-data.sh can't load lib!" > $MODDIR/boot.log ; exit 1; }

mkdir -p "$ROOT/log"
mkdir -p "$CORE_DIR"
mkdir -p "$DATA_DIR"

mount -o bind "$CORE_INTERNAL_DIR" "$CORE_DIR"
mount -o bind "$DATA_INTERNAL_DIR" "$DATA_DIR"
