# SmartDNS - Android

这是一个 [Magisk](https://github.com/topjohnwu/Magisk) 模块，使 [SmartDNS](https://github.com/pymumu/smartdns) 运行在安卓设备上。使用shell脚本控制其的启动与停止以及达到某些目的。

- 有关 SmartDNS 的信息详情请看 [官方文档](https://github.com/pymumu/smartdns/blob/master/ReadMe.md) 。
- **使用前请阅读** [声明](#声明) 。

## 需求

- arm, arm64, x86, x64 指令集
- Magisk v20.0+
- Busybox (建议安装模块 Busybox for Android NDK by osm0sis @ xda-developers)
- 在 Android 9+ 系统上使用，请关闭系统设置中的私人DNS，它会导致模块失效。

## 安装

下载 zip，请在 Magisk Manager 中刷入。目前并未考虑Recovery中刷入

- 默认配置 **仅供参考** ，务必 **自行配置**。具体参考 [配置文件](#配置文件) 。

- 刷入后续更新时，会尝试继承脚本配置，但有可能因为参数变化而导致意料之外的错误。请备份配置之后自行调整。

## 配置文件

### Smartdns 配置

配置文件位于 `/data/adb/smartdns/smartdns.conf` ，如果你不知道你在干什么，请保持下列参数为默认值

|参数|功能|默认|
|--|--|--|
|cache-file|缓存持久化文件路径|cache-file /dev/smartdns/tmp/dns_cache
|log-file|日志文件路径|log-file /dev/smartdns/log/server.log
|audit-file|审计文件路径|audit-file /dev/smartdns/log/audit.log
|ca-file|证书文件|ca-file /dev/smartdns/binary/CA/ca-certificates.crt
|ca-path|证书文件路径|ca-path /dev/smartdns/binary/CA

其他参数设置，请参考 [配置参数](https://github.com/pymumu/smartdns/blob/master/ReadMe.md#配置参数)

### 控制脚本配置

配置文件位于 `/data/adb/smartdns/script_conf.sh` ，脚本参数影响 iptables 规则和服务控制，在一般情况下不需要修改。修改之前，务必确保服务已经停止。

|参数|功能|
|--|--|
|log|生成脚本运行日志|
|language|脚本提示信息的语言|
|Main_PORT|主要监听端口，处理本地流量|
|Second_PORT|次要监听端口，处理代理流量 (为空时使用 Main_PORT 的值)|
|ServerUID|服务器权限 (只能在arm64设备上使用，非arm64设备只能是root)|
|MODE|工作模式|
|TUN|不重定向走 VPN(tun) 的数据包|
|WLAN|不重定向走 WiFi(wlan) 的数据包|
|DATA|不重定向走 DATA(rmnet_data) 的数据包|
|PKG|不重定向特定应用的数据包 (填包名或UID，用空格分隔)|
|IP6T_BLOCK|封锁或重定向本机 IPv6 网络上的数据包|
|STRICT|仅在连接私人局域网时创建端口转发(到代理端口)|

工作模式介绍

```txt
local  (L) : 本机发出到53端口的数据包重定向到 Main_PORT (默认)
       (P) : 发往本机53端口的数据包重定向到 Second_PORT (不支持IPv6)
proxy  (LP) : 结合上面两项
server () : 不控制 iptables ，仅启动服务器和运行其他脚本
```

PKG & ServerUID 介绍

iptables 不会重定向在 `PKG` 和 `ServerUID` 中对应的 uid 所发出的查询。
ServerUID: 让服务器以 root 或者 radio 权限运行。通常用于减少对部分抓包软件造成的影响。这个参数目前只能在 arm64 设备上使用，非 arm64 设备只能以 root 权限运行。

IP6T_BLOCK 介绍

IPv6 重定向需要运行完全支持 ip6tables(CONFIG_IP6_NF_*) 的内核的 Android 设备，大多数情况下您必须自己编译内核。如果您的设备内核不支持，会自动转为封锁。

### 配置建议

- 启动服务器时，请确保有互联网连接。上游优先指定 IP，至少保留一个IP地址形式的上游服务器，用以解析域名形式的上游服务器。

### 异常解决

使用 `smartdns -clean` 命令可以使 iptables 恢复至开机后首次启动时记录的状态。会对使用到 iptables 的程序造成一些影响。

### 代理类应用兼容性

以下方案仅供参考，请自行调整相关应用中与 DNS相关 的处理。

1. [Adguard](https://github.com/AdguardTeam/AdguardForAndroid): 重定向可交由Adguard实现。应用设置 `DNS - 选择 DNS 服务器` 指向 127.0.0.1:(监听端口)；当脚本参数 `ServerUID` 为 `root` 时，应用设置 `高级 - 低级设置 - pref.excluded.packages` 添加一行内容: `0` 。脚本参数 `MODE` 可以不管，或者设置为 `server`。

1. [Clash](https://github.com/Kr328/ClashForAndroid): 默认设置下，会交由 Clash 完成处理，SmartDNS 不参与。

## 命令

使用终端等工具 以Root权限执行

以下是常用命令

```shell
smartdns [options]
~ start
# (重)启动服务

~ stop
# 停止服务

~ status
# 服务状态

~ clean
# 停止服务并恢复 iptables 到初始状态

~ -h, --help
# 帮助信息
```

## 感谢

- [SmartDNS](https://github.com/pymumu/smartdns) | pymumu
- [ClashForMagisk](https://github.com/Kr328/ClashForMagisk) | Kr328
- [GitHub520](https://github.com/521xueweihan/GitHub520)

## 捐赠

如果你觉得 SmartDNS 对你有帮助，请捐助 **[原作者](https://github.com/pymumu/smartdns/blob/master/ReadMe.md#捐赠)** ，以使项目能持续发展，更加完善。

## 声明

### 如果您下载且安装 SmartDNS，则表示认同声明协议

- `SmartDNS` 著作权归属 Nick Peng (pymumu at gmail.com)。
- `SmartDNS` 为免费软件，用户可以非商业性地复制和使用 `SmartDNS`。
- 禁止将 `SmartDNS` 用于商业用途。
- 使用本软件的风险由用户自行承担，在适用法律允许的最大范围内，对因使用本产品所产生的损害及风险，包括但不限于直接或间接的个人损害、商业赢利的丧失、贸易中断、商业信息的丢失或任何其它经济损失，不承担任何责任。
- 本软件不会未经用户同意收集任何用户信息。
