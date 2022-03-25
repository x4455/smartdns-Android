#!/system/bin/sh
# 为脚本提供常用函数

### 路径类 ###
MODDIR="/data/adb/modules/smartdns"
. $MODDIR/constant.sh
# 临时文件路径
readonly TEMP_PATH="$TEMP_DIR/scripts_$RANDOM"


### 函数类 ###

# 重载配置数据 #
reload_config() {
	smartdns status >/dev/null 2>&1
	if [ "$?" != '3' ]; then
		echo '[info]: 加载新数据, 服务器重启中'
		smartdns start
	fi
}

# 下载文件 E7KMbb/AD-hosts 
download_links() {
	# $1 链接	$2 下载文件名
	local file_link=$1 file_name=$2
	if $(curl -V > /dev/null 2>&1) ; then
		for i in $(seq 1 20); do
			if curl "${file_link}" -k -L -o "$file_name" >&2; then
				break;
			fi
			sleep 2
			if [[ $i == 20 ]]; then
				echo "[warn]: curl连接失败, 更新失败"
				rm -rf $file_name
				return 1
			fi
		done
	elif $(wget --help > /dev/null 2>&1) ; then
		for i in $(seq 1 5); do
			if wget --no-check-certificate ${file_link} -O $file_name; then
				break;
			fi
			if [[ $i == 5 ]]; then
				echo "[warn]: wget连接失败, 更新失败"
				rm -rf $file_name
				return 1
			fi
		done
	else
		echo "[error]: 您没有下载所需要用到的指令文件, 请安装Busybox for Android NDK模块"
		return 1
	fi
}

# hosts 处理函数 #
# smartdns 不支持设定多个A记录，这里提供去重以简化配置

# hosts格式转换为smartdns格式 保留注释
hosts2smartdns() {
	local input_file=$1 output_file=$2
	# 通用转换格式
	awk '$1 !~ /#/ {printf"address /%s/%s\n",$2,$1} $1 ~ /#/ {printf"%s\n",$0}' $input_file > $output_file
}

# 顺序去重 保留注释 去除后续重复条目 转化格式
hosts_sort() {
	local input_hosts=$1 output_file=$2
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

	# 简易去重
	#nl -ba -nrz hosts | sort -k2 -u | sort | cut -f2 > hosts_sort

}

# 随机去重 保留注释 随机去除重复条目 转化格式
hosts_sort_roll() {
	local input_hosts=$1 output_file=$2
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
	# 转换格式（本函数专用？）
	awk '$1 !~ /#/ && $0 != "" {printf"address /%s/%s\n",$2,$1}; $1 ~ /#/ {print}; $0 = /^$/ {printf"\n"};' hosts_sort > $output_file
	# 清理文件
	rm hosts_list hosts_sort hosts_note hosts_uniq
}
