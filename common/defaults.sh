#!/system/bin/sh
# Generate script work log
# 生成脚本工作日志
# [yes|no]
log='no'
# language
# [en|zh-CN]
language='zh-CN'



### Make sure to stop the server before modifying the parameters
### 在修改配置之前，确保已停止服务

# Main listen port
# 主要监听端口
Main_PORT='6053'
# Secondary listen port
# 次要监听端口
Second_PORT=''

# Service Mode
# 工作模式
# [local/proxy|server]
MODE='local'

# Bypass tun+  wlan+  data+
# 放行通过对应网卡的数据包
# [yes|no]
TUN='yes'
WLAN='no'
DATA='no'

# Bypass redirect applications
# [PackageName or UID]
# 放行应用
# [包名 或 UID]
PKG='com.github.shadowsocks com.v2ray.ang com.github.kr328.clash'

# Block IPv6 port 53
# 封锁本机 IPv6 的数据包
# [yes|no]
IP6T_BLOCK='yes'
