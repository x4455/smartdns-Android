#!/system/bin/sh
# 加载 lib.sh
SCRIPT_INTERNAL_DIR=${0%/*/*/*}
. $SCRIPT_INTERNAL_DIR/lib.sh

# 最小更新间隔 (单位 小时 正整数)
minInterval='2'
update_file="$DATA_INTERNAL_DIR/hosts/steam.txt"

file_update_interval $update_file $minInterval || exit 0

mkdir -p $SCRIPT_TEMP_DIR
cd $SCRIPT_TEMP_DIR
# https://raw.githubusercontent.com/pboymt/Steam520/main/hosts
download_links 'https://cdn.jsdelivr.net/gh/pboymt/Steam520/hosts' 'hosts_raw'
hosts2smartdns_sort_roll 'hosts_raw' 'hosts'
if [ "$?" == '0' ]; then
	check_md5 'hosts' $update_file
	if [ "$?" != '0' ]; then
		cp -f 'hosts' $update_file
		echo '[info]: 文件已更新'
		chmod 0644 $update_file
		# 重载配置
		reload_config
	fi
fi
rm -r $SCRIPT_TEMP_DIR
