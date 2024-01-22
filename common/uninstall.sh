#!/system/bin/sh
# 加载参数
. ${0%/*}/constant.sh
. $SCRIPT_INTERNAL_DIR/lib.sh
# 配置
rm -r /data/adb/$CORE_NAME
# 脚本临时文件夹
rm -r ${SCRIPT_TEMP_DIR%/*}