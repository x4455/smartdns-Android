#!/system/bin/sh
. ${0%/*}/lib.sh
rm -rf $DATA_INTERNAL_DIR 2>/dev/null
rm -rf $(readlink -f ${0%/*}) 2>/dev/null
exit 0
