#!/system/bin/sh
print_help() {
cat << HELP
用法: $CORE_NAME [ OPTIONS ]
  start
    启动服务
  run-mod
    运行mod脚本
  stop
    停止服务
  status
    服务状态
  clean
    恢复原始防火墙规则并停止服务器
  --mode [ local / proxy / server ]
    ├─ local: 代理本地查询
    ├─ proxy: 代理外部查询
    └─ server: 仅运行服务器
HELP
exit $1
# Usage: $CORE_NAME [ OPTIONS ]
#   start
#     Start service
#   run-mod
#     Run Mod script
#   stop
#     Stop service
#   status
#     Service status
#   clean
#     Restore origin iptables rules and stop server
#   --mode [ local / proxy / server ]
#     ├─ local: Proxy local query
#     ├─ proxy: Proxy other query
#     └─ server: Expecting the server
}

# 服务 状态报告

print_status_server_already_running() {
	echo '[信息]: 服务器 已经启动'
	# echo '[Info]: server is running.'
}

print_status_server_not_running() {
	echo '[信息]: 服务器 已经停止'
	# echo '[Info]: server is stopped.'
}

print_status_iptRules_Local_not_added() {
	echo '[信息]: 规则 本地 尚未加载'
	# echo '[Info]: LocalRules not added.'
}

print_status_iptRules_Proxy_not_added() {
	echo '[信息]: 规则 代理 尚未加载'
	# echo '[Info]: ProxyRules not added.'
}

print_status_iptRules_added() {
	echo '[信息]: 防火墙规则 已经加载'
	# echo '[Info]: iptables rules loaded.'
}

# 服务 程序 启动报告

print_server_start_failed(){
	echo '[错误]: 服务器 启动失败'
	# echo '[Error]: start server failed.'
}

print_server_start_success(){
	echo '[信息]: 服务器 成功启动'
	# echo '[Info]: start server success.'
}

# 服务 程序 停止报告

print_server_stop_failed(){
	echo '[错误]: 服务器 停止失败'
	# echo '[Error]: stop server failed.'
}

print_server_stop_success(){
	echo '[信息]: 服务器 成功停止'
	# echo '[Info]: stop server success.'
}

# 提示消息

print_invalid_argument(){
	echo "[错误]: 无效的参数: $1\n"
	# echo "[Error]: Invalid argument: $1\n"
}

print_invalid_value(){
	echo "[错误]: 无效的值: $1"
	# echo "[Error]: Invalid value: $1"
}

print_reset_network(){
	echo '[信息]: 网络设置已重置'
	# echo '[Info]: Network settings are reset.'
}

# 提示消息 其他

print_kernel_not_support(){
	echo -e '[信息]: 你的内核不支持 IPv6 nat'
	# echo -e '[Info]: Your kernel not support IPv6 nat.'
}

print_listenPort_not_set(){
	echo '[错误]: 主监听端口未设置'
	# echo '[Error]: Main_PORT not set.'
}

print_iptRules_remove_errors(){
	echo -e "[错误]: 防火墙规则 移除出错\n[信息]: 运行 \`$CORE_NAME -clean\` 以重置网络设置"
	# echo -e "[Error]: iptrules remove error.\n[Info]: Run \`$CORE_NAME -clean\` to reset network settings."
}
