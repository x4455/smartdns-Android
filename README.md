# SmartDNS - Android

## 测试机坏了，目前发布的模块均 *未经测试*
## 没有精力去确保更新质量，今后随缘更新

这是一个 [Magisk](https://github.com/topjohnwu/Magisk) 模块，使 [SmartDNS](https://github.com/pymumu/smartdns) 运行在安卓设备上。使用 shell 脚本控制其的启动与停止以及达到某些目的。

- 有关 SmartDNS 的信息详情请看 [官方文档](https://github.com/pymumu/smartdns/blob/master/ReadMe.md) 。
- **使用前请阅读 [声明](#声明)** 。

## 需求

- arm, arm64 指令集
- Magisk v20.0+
- Busybox (建议安装模块 Busybox for Android NDK by osm0sis @ xda-developers)
- 在 Android 9+ 系统上使用，请关闭系统设置中的私人DNS，它会导致**模块失效**。

## 安装

[下载zip](https://github.com/x4455/smartdns-Android/releases/latest) 后，在 Magisk Manager 中刷入。

- 更新模块时，可能会因为参数变化而导致错误，请在刷入之后自行调整。
- 为了避免更新导致错误或数据丢失，自动脚本**不会主动更新**。

### 恢复默认配置

使用终端等工具，刷入前以Root权限执行以下命令

- *配置文件*: `touch /data/adb/smartdns/config/reset`
- *自动脚本*: `touch /data/adb/smartdns/scripts/reset`

## 配置文件

因网络环境的不可靠性，不对默认配置的可用性负责，**仅供参考**。请根据自身的网络情况 **自行配置**，具体参考 [配置文件](#配置文件) 进行配置。

### Smartdns 配置

配置文件位于 `/data/adb/smartdns/config/smartdns.conf`。如果你不知道你在干什么，请保持下列参数为默认值

|参数|功能|默认|
|--|--|--|
|cache-file|缓存持久化文件路径|cache-file /dev/smartdns/tmp/dns_cache
|log-file|日志文件路径|log-file /dev/smartdns/log/server.log
|audit-file|审计文件路径|audit-file /dev/smartdns/log/audit.log
|ca-file|证书文件|ca-file /dev/smartdns/binary/CA/ca-certificates.crt
|ca-path|证书文件路径|ca-path /dev/smartdns/binary/CA

其他参数设置，请参考 [配置参数](https://github.com/pymumu/smartdns/blob/master/ReadMe.md#配置参数)

黑白名单

- 如果一个查询返回多个ip的结果，只要其中一个在blacklist中，该结果整个丢弃。
- 如果一个查询返回多个ip的结果，但没有任何结果符合whitelist，该结果整个丢弃。

### 控制脚本配置

配置文件位于 `/data/adb/smartdns/config/script_conf.sh`。脚本参数影响 iptables 规则和服务控制。修改之前，务必确保服务已经停止。

|参数|功能|
|--|--|
|log|生成脚本运行日志|
|language|脚本提示信息的语言|
|Main_PORT|主要监听端口，处理本地流量|
|Second_PORT|次要监听端口，处理代理流量 (为空时使用 Main_PORT 的值)|
|MODE|工作模式|
|TUN|不重定向走 VPN(tun) 的数据包|
|WLAN|不重定向走 WiFi(wlan) 的数据包|
|DATA|不重定向走 DATA(rmnet_data) 的数据包|
|PKG|不重定向特定应用的数据包 (填包名或UID，用空格分隔)|
|IP6T_BLOCK|封锁或重定向本机 IPv6 网络上的数据包|

工作模式介绍

```txt
local         : 本机发出到53端口的数据包重定向到 Main_PORT (默认)
proxy         : 发往本机53端口的数据包重定向到 Second_PORT
local,proxy   : 结合上面俩项
server        : 仅启动服务器 (任务脚本照常运行)
```

PKG 介绍

- iptables 不会重定向在 `PKG` 中包名所对应的 UID 所发出的查询。另外，以 `root` `radio` 身份发出的查询也会放行。

IP6T_BLOCK 介绍

- IPv6 重定向需要运行完全支持 ip6tables(CONFIG_IP6_NF_*) 的内核的 Android 设备，大多数情况下您必须自己编译内核。如果您的设备内核不支持，会自动转为封锁。

### 任务脚本

在设定时间执行 shell 脚本。文件结构遵循下面的示例。

```txt
/data/adb/smartdns/scripts
 │      *** 开机任务脚本 ***
 ├─── bootTask
 │   ├─── crond             <--- 任务目录
 │   │   └─── boot.sh       <--- 主脚本 (名称必须为 boot.sh)
 │   └─── ...
 │      *** 定时任务脚本 ***
 ├─── cronTask
 │   ├─── hosts_update      <--- 任务目录
 │   │   ├─── crond.reg     <--- 注册执行时间 (名称必须为 crond.reg)
 │   │   └─── GitHub.sh     <--- 脚本
 │   └─── ...
 └─── lib.sh                <--- 常用脚本函数
```

### 使用&配置 建议

- 服务启动时，请确保互联网连接通畅。长时间断网可能会导致解析异常。
- 上游服务器优先指定 IP，至少需要一个IP地址形式的上游服务器，用以解析域名形式的上游服务器。
- 同一个地址，一般没有必要配置多种协议。

## 异常解决

- 使用 `smartdns -clean` 命令清理可。这会尝试将 iptables 恢复至开机后首次启动时记录的状态，会对使用到 iptables 的程序造成一些影响。

### 代理类应用兼容性

当参数`TUN='yes'`时(默认), 对于启用 VPN (即屏幕顶部出现一个🗝️图标)后

#### 以下方案**仅供参考**，请自行调整相关应用中与 DNS相关 的处理。

- [Adguard](https://github.com/AdguardTeam/AdguardForAndroid):

1. 本地VPN模式兼容性不好，需换成HTTP代理，`网络 -> 过滤方式 -> 本地HTTP代理`
1. DNS指向 `127.0.0.1:(填监听端口)` ，`DNS -> 选择 DNS 服务器 -> 添加自定义DNS服务器`
1. 为 root 添加放行规则， `高级 -> 低级设置 -> pref.excluded.packages` 添加一行内容: `0` 。
1. 控制脚本配置中的参数 `MODE` 设置为 `server`。

- [Clash](https://github.com/Kr328/ClashForAndroid):

1. 默认设置下 SmartDNS 不参与，交由 Clash 完成处理。如需有需要，自行调整。

## 命令

使用终端等工具 以Root权限执行，以下是常用命令

```shell
smartdns [options]
~ start
# 启动服务

~ stop
# 停止服务

~ status
# 服务状态

~ clean
# 清理服务并恢复 iptables 到初始状态

~ -h, --help
# 帮助信息
```

## 感谢

- [SmartDNS](https://github.com/pymumu/smartdns) | pymumu
- [ClashForMagisk](https://github.com/Kr328/ClashForMagisk) | Kr328

### 规则来源

- [AD-hosts](https://github.com/E7KMbb/AD-hosts) | E7KMbb
- [GitHub520](https://github.com/521xueweihan/GitHub520) | 521xueweihan

## 捐赠

如果你觉得 SmartDNS 对你有帮助，请捐助 **[原作者](https://github.com/pymumu/smartdns/blob/master/ReadMe.md#捐赠)** ，以使项目能持续发展，更加完善。

## 声明

### 如果您下载且安装 SmartDNS，则表示认同声明协议

- `SmartDNS` 著作权归属 Nick Peng (pymumu at gmail.com)。
- `SmartDNS` 为免费软件，用户可以非商业性地复制和使用 `SmartDNS`。
- 禁止将 `SmartDNS` 用于商业用途。
- 使用本软件的风险由用户自行承担，在适用法律允许的最大范围内，对因使用本产品所产生的损害及风险，包括但不限于直接或间接的个人损害、商业赢利的丧失、贸易中断、商业信息的丢失或任何其它经济损失，不承担任何责任。
- 本软件不会未经用户同意收集任何用户信息。
