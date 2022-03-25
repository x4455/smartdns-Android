#!/system/bin/sh
print_help() {
cat << HELP
Usage: smartdns [ OPTIONS ]
  start
    Start service
  run-mod
    Run Mod script
  stop
    Stop service
  status
    Service status
  clean
    Restore origin rules and stop server
  -m, --mode [ local / proxy / server ]
    ├─ local: Proxy local only
    ├─ proxy: Proxy local and other query
    └─ server: Expecting the server only
HELP
exit $1
}

# 服务 状态报告

print_status_server_already_running() {
	echo '[Info]: server is running.'
}

print_status_server_not_running() {
	echo '[Info]: server is stopped.'
}

print_status_iptRules_Local_not_added() {
	echo '[Info]: LocalRules not added.'
}

print_status_iptRules_Proxy_not_added() {
	echo '[Info]: ProxyRules not added.'
}

print_status_iptRules_added() {
	echo '[Info]: iptables rules loaded.'
}

# 服务 程序 启动报告

print_server_start_failed(){
	echo '[Error]: start server failed.'
}

print_server_start_success(){
	echo '[Info]: start server success.'
}

# 服务 程序 停止报告

print_server_stop_stopped(){
	echo '[Info]: server is stopped.'
}

print_server_stop_failed(){
	echo '[Error]: stop server failed.'
}

print_server_stop_success(){
	echo '[Info]: stop server success.'
}

# 提示消息

print_invalid_argument(){
	echo "[Error]: Invalid argument: $1\n"
}

print_invalid_value(){
	echo "[Error]: Invalid value: $1"
}

print_reset_network(){
	echo '[Info]: Network settings are reset.'
}

# 提示消息 其他

print_kernel_not_support(){
	echo -e '[Info]: Your kernel not support IPv6 nat.'
}

print_listenPort_not_set(){
	echo '[Error]: Main_PORT not set.'
}

print_iptRules_remove_errors(){
	echo -e '[Error]: iptrules remove error.\n[Info]: Run \`smartdns -clean\` to reset network settings.'
}
