#!/system/bin/sh
# 为脚本提供常用函数

CORE_NAME="smartdns"
MODDIR="/data/adb/modules/$CORE_NAME"
. $MODDIR/constant.sh

### 路径类 ###
# 临时文件路径
readonly SCRIPT_TEMP_DIR="/data/local/tmp/$CORE_NAME/scripts_$RANDOM"
readonly LOG_DIR="$LOG_DIR/scripts"

### 函数类 ###

# 文件更新间隔
file_update_interval() {
	# $1 文件路径 $2 最小间隔(小时)
	local file="$1" Interval="$2"
	# 检测命令
	type stat > /dev/null 2>&1
	if [ "$?" != '0' ]; then
		# 不可用 强制更新
		printf '[warn]: stat 命令不存在\n'
		return 0
	else
		# 获取时间戳
		timestamp=$(date +%s)
		[ -e "$file" ] && filestamp=`stat -c %Y $file` || filestamp='0'
		if [ "$(($timestamp - $filestamp))" -gt "$(($Interval * 3600))" ]; then
			return 0
		fi
	fi
	return 1
}

# 文件变化
check_md5() {
	# $1 $2 文件路径
	if [ "`md5sum "${1}" | awk '{print $1}'`" == "`md5sum "${2}" | awk '{print $1}'`" ]; then
		return 0
	else
		return 1
	fi
}

# 重载配置数据
reload_config() {
	$CORE_NAME status >/dev/null 2>&1
	if [ "$?" != '3' ]; then
		echo '[info]: 加载新数据, 重启服务器'
		$CORE_NAME start
	fi
}

# 下载文件 E7KMbb/AD-hosts 
download_links() {
	# $1 链接	$2 下载文件名
	local file_link="$1" file_name="$2" tries

	if $(curl -V > /dev/null 2>&1) ; then
		for tries in $(seq 1 20); do
			if curl "${file_link}" -k -L -o "$file_name" >&2; then
				break;
			fi
			sleep 2
			if [[ $tries == 20 ]]; then
				echo '[warn]: curl连接失败, 更新失败'
				rm -rf $file_name
				return 1
			fi
		done
	elif $(wget --help > /dev/null 2>&1) ; then
		for tries in $(seq 1 5); do
			if wget --no-check-certificate ${file_link} -O $file_name; then
				break;
			fi
			if [[ $tries == 5 ]]; then
				echo '[warn]: wget连接失败, 更新失败'
				rm -rf $file_name
				return 1
			fi
		done
	else
		echo '[error]: 您没有下载所需要用到的指令文件, 请安装Busybox for Android NDK模块'
		return 1
	fi
}

# 封锁类型
blackhole() {
	# $1 文件路径(需要smartdns格式)
	sed -i "s/127.0.0.1/#/g" $1
	sed -i "s/0.0.0.0/#/g" $1
	sed -i "s/::1/#/g" $1
	sed -i "s/::/#/g" $1
	# 分辨#注释
	[ "${2}" == '#' ] || sed -i "s/\/#/\/${2}/g" "$1"
}

# hosts 处理函数 #
# smartdns 不支持设定多个A记录等，这里提供去重以简化配置

# hosts格式转换为smartdns格式 保留注释
hosts2smartdns() {
	local input_hosts="$1" output_file="$2"
	# 通用转换格式
	awk '$1 !~ /#/ {printf"address /%s/%s\n",$2,$1} $1 ~ /#/ {printf"%s\n",$0}' $input_hosts > $output_file
}

# 简易去重
# nl -ba -nrz $input_hosts | sort -k2 -u | sort | cut -f2 > $output_file

# 顺序去重 保留注释 去除后续重复条目 转化格式
hosts2smartdns_sort() {
	local input_hosts="$1" output_file="$2"
	# 初始排序 #降序 sort -k 3 -k 2r
	cat $input_hosts | nl | sort -k 3 -k 2 > hosts_sort
	# 提取注释
	awk '$2 ~ /#/ {printf"%s\n",$0}' hosts_sort > hosts_note
	# 不含注释去重
	awk '$2 !~ /#/ {printf"%s\n",$0}' hosts_sort | uniq -f 2 > hosts_uniq
	# 合并排序 移除序号&空格
	cat hosts_note hosts_uniq | sort -n -k 1 | awk '{$1="";print $0}' | sed -e 's/^ //' > hosts_sort
	# 转换格式（通用）
	awk '$1 !~ /#/ {printf"address /%s/%s\n",$2,$1} $1 ~ /#/ {printf"%s\n",$0}' hosts_sort > $output_file
	# 清理文件
	rm hosts_sort hosts_note hosts_uniq
}

# 随机去重 保留注释 随机去除重复条目 转化格式
hosts2smartdns_sort_roll() {
	local input_hosts="$1" output_file="$2"
	# 放置顺序编号
	cat $input_hosts | nl -b a > hosts_list
	# 提取注释&空行，暂存到文件
	awk '$2 ~ /#/ /[\s\t]*[0-9]+[\s\t]*$/' hosts_list > hosts_note
	# 剔除上面搜索到的条目
	grep -v -f hosts_note hosts_list > hosts_sort
	# 不含注释&空行的条目 | 随机数 | 排序 优先级(域名,随机数) | 去除随机数 | 去重(忽略前两列上的数据？)
	cat hosts_sort | awk -F"\3" 'BEGIN{srand();}{value=int(rand()*10000000); print value"\3"$0 }' | sort -f -k 4 -k 1 | awk -F"\3" '{print $2}' | uniq -f 2 > hosts_uniq
	# 合并条目 | 顺序编号重新排序 | 移除序号&空格
	cat hosts_note hosts_uniq | sort -k 1 -n | awk '{$1="";print $0}' | sed -e 's/^ //' > hosts_sort
	# 转换格式（本函数专用?）
	awk '$1 !~ /#/ && $0 != "" {printf"address /%s/%s\n",$2,$1}; $1 ~ /#/ {print}; $0 = /^$/ {printf"\n"};' hosts_sort > $output_file
	# 清理文件
	rm hosts_list hosts_sort hosts_note hosts_uniq
}
