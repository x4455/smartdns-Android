#!/system/bin/sh
# Generate script work log
# 生成脚本工作日志
log=no
# language 语言
# en / zh-CN
language=zh-CN



### Make sure to stop the server before modifying the parameters
### 在修改配置之前，确保已停止服务

# Main listen port
# 主要监听端口
Main_PORT='6053'
# Secondary listen port
# 次要监听端口
Second_PORT=''
# Change the program UID to reduce the impact in some packet capture software
# 更改程序UID，减少在部分抓包软件中造成的影响
# root / radio
ServerUID='root'

# Service Mode    Only run server | Local | Proxy
# 工作模式    仅运行服务器 | 本机的53数据包 | 所有收到的53数据包
# '' (null) / L | P
MODE='L'

# Bypass tun+ / wlan+ / data+
# 放行通过对应网卡的数据包
# yes / no
TUN=yes
WLAN=no
DATA=no

# Bypass redirect applications
# 放行应用
# PackageName or UID (包名 或 UID)
PKG='com.github.shadowsocks com.v2ray.ang com.github.kr328.clash'

# Block IPv6 port 53
# 封锁本机 IPv6 的数据包
# yes / no
IP6T_BLOCK=yes

# Do not create redirection to proxy ports in non-LAN (rfc1918_filter)
# 不在非局域网中创建重定向到代理端口
# yes / no
STRICT=yes
