#!/system/bin/sh
# 加载 lib.sh
SCRIPT_INTERNAL_DIR=${0%/*/*/*}
. $SCRIPT_INTERNAL_DIR/lib.sh

# 最小更新间隔 (单位 小时 正整数)
minInterval='2'
update_file="$DATA_INTERNAL_DIR/hosts/github.txt"

# ipaddress_com(){
# 	local model="$(getprop ro.product.model)"
# 	local version=$(echo $(($(($RANDOM%3))+9)))
# 	local ua="Mozilla/5.0 (Linux; Android ${version}; ${model}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.115 Mobile Safari/537.36"

# 	GitHub_IP1=`curl --user-agent "$ua" -skL "https://github.com.ipaddress.com/" | egrep -o '<li>[0-9.]{11,}</li>' | egrep -o -m 1 '[0-9.]{11,}'`
# 	GitHub_IP2=`curl --user-agent "$ua" -skL "https://fastly.net.ipaddress.com/github.global.ssl.fastly.net" | egrep -o '<li>[0-9.]{11,}</li>' | egrep -o -m 1 '[0-9.]{11,}'`
# 	GitHub_IP3=`curl --user-agent "$ua" -skL "https://github.com.ipaddress.com/assets-cdn.github.com" | egrep -o '<li>[0-9.]{11,}</li>' | egrep -o -m 1 '[0-9.]{11,}'`
# 	GitHub_IP4=`curl --user-agent "$ua" -skL "https://githubusercontent.com.ipaddress.com/raw.githubusercontent.com" | egrep -o '<li>[0-9.]{11,}</li>' | egrep -o -m 1 '[0-9.]{11,}'`

# 	echo -e "# Date: $(date +%c)\n" > $update_file
# 	[ -n "$GitHub_IP1" ] && echo -e "address /github.com/$GitHub_IP1\naddress /www.github.com/$GitHub_IP1" >> $update_file
# 	[ -n "$GitHub_IP2" ] && echo "address /github.global.ssl.fastly.net/$GitHub_IP2" >> $update_file
# 	[ -n "$GitHub_IP3" ] && echo "address /assets-cdn.github.com/$GitHub_IP3" >> $update_file
# 	[ -n "$GitHub_IP4" ] && echo "address /raw.githubusercontent.com/$GitHub_IP4" >> $update_file

# 	chmod 0644 $update_file
# 	# 重载配置
# 	reload_config
# }

file_update_interval $update_file $minInterval || exit 0

mkdir -p $SCRIPT_TEMP_DIR
cd $SCRIPT_TEMP_DIR
download_links 'https://raw.hellogithub.com/hosts' 'hosts_raw'
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
