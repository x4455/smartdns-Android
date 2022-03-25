#!/system/bin/sh
# GitHub access acceleration hosts

# 注册 crontab
# 执行间隔
# 0,30 */2 * * * sh /data/adb/smartdns/scripts/cronTask/hosts_github.sh

. ${0%/*/*}/lib.sh
update_file="$DATA_INTERNAL_DIR/hosts/github.txt"
# 最小更新间隔 单位 小时(int)
minInterval=2

ipaddress_com(){
	local model="$(getprop ro.product.model)"
	local version=$(echo $(($(($RANDOM%3))+9)))
	local ua="Mozilla/5.0 (Linux; Android ${version}; ${model}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.115 Mobile Safari/537.36"

	GitHub_IP1=`curl --user-agent "$ua" -skL "https://github.com.ipaddress.com/" | egrep -o '<li>[0-9.]{11,}</li>' | egrep -o -m 1 '[0-9.]{11,}'`
	GitHub_IP2=`curl --user-agent "$ua" -skL "https://fastly.net.ipaddress.com/github.global.ssl.fastly.net" | egrep -o '<li>[0-9.]{11,}</li>' | egrep -o -m 1 '[0-9.]{11,}'`
	GitHub_IP3=`curl --user-agent "$ua" -skL "https://github.com.ipaddress.com/assets-cdn.github.com" | egrep -o '<li>[0-9.]{11,}</li>' | egrep -o -m 1 '[0-9.]{11,}'`
	GitHub_IP4=`curl --user-agent "$ua" -skL "https://githubusercontent.com.ipaddress.com/raw.githubusercontent.com" | egrep -o '<li>[0-9.]{11,}</li>' | egrep -o -m 1 '[0-9.]{11,}'`

	echo -e "# Date: $(date +%c)\n" > $update_file
	[ -n "$GitHub_IP1" ] && echo -e "address /github.com/$GitHub_IP1\naddress /www.github.com/$GitHub_IP1" >> $update_file
	[ -n "$GitHub_IP2" ] && echo "address /github.global.ssl.fastly.net/$GitHub_IP2" >> $update_file
	[ -n "$GitHub_IP3" ] && echo "address /assets-cdn.github.com/$GitHub_IP3" >> $update_file
	[ -n "$GitHub_IP4" ] && echo "address /raw.githubusercontent.com/$GitHub_IP4" >> $update_file

	chmod 0644 $update_file
	# 重载配置
	reload_config
}

github520() {
	mkdir -p $TEMP_PATH
	cd $TEMP_PATH
	download_links 'https://raw.hellogithub.com/hosts' 'github_hosts_raw'
	hosts_sort_roll 'github_hosts_raw' 'github_hosts'
	if [ "$?" == '0' ]; then
		cp -f github_hosts $update_file
		echo '[info]: 文件已更新'
		chmod 0644 $update_file
		# 重载配置
		reload_config
	fi
	rm -rf $TEMP_PATH
}

# 获取时间戳
timestamp=$(date +%s)
# 检测命令
type stat >/dev/null 2>&1
if [ "$?" != '0' ]; then
	# 不可用
	printf '[warn]: stat 命令不存在\n'
	filestamp=0
else
	# 强制更新
	if [ ! -e $update_file ]; then
		filestamp=0
	else
		filestamp=$(stat -c %Y $update_file)
	fi
fi
# 达到最小更新间隔时启动更新
if [ "`expr $timestamp - $filestamp`" -gt "`expr $minInterval \* 3600`" ]; then
	#ipaddress_com
	github520
fi
