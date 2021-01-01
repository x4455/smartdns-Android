# SmartDNS - Android

这是一个 Magisk 模块。为 SmartDNS 提供在安卓设备运行的环境和自动化控制脚本

![SmartDNS](https://raw.github.com/pymumu/smartdns/master/doc/smartdns-banner.png)
SmartDNS是一个运行在本地的DNS服务器。SmartDNS会从多个上游DNS服务器获取DNS查询结果，并将访问速度最快的结果返回给客户端，提高网络访问速度。

- 详情请看 [官方文档](https://github.com/pymumu/smartdns/blob/master/ReadMe.md) 。
- 使用前请阅读 [声明](#声明) 。

## 需求

- arm, arm64, x86, x64 指令集
- Magisk v20.0+
- Busybox (建议安装 Busybox for Android NDK by osm0sis @ xda-developers 模块)

## 安装

下载 zip，在 Magisk Manager 或 Recovery 中刷入。

- 默认配置中并未设置上游，最好不要修改已配置好的路径。安装完成后，务必自行修改配置。具体参考 [配置参数](#配置参数) 说明。
- 如果在 Magisk Manager 中刷入后续更新，会尝试继承脚本配置。但有可能因为参数变化而导致意料之外的错误，届时请自行重置。

## 脚本控制

获取 su 后执行 Shell
以下是常用命令

```shell
smartdns [options]
~ start
# (重)启动服务

~ stop
# 停止服务

~ status
# 服务状态

~ -clean
# 恢复初始规则并停止服务

~ -h, --help
# 帮助信息

~ --ip6block [true/false]
# 封锁ipv6查询，否则进行重定向
```

## 配置文件路径

位于 /data/adb/smartdns-data/ 文件夹，主配置文件为 ./smartdns.conf 。脚本配置文件为 ./script.conf

- 脚本配置影响 iptables 规则和服务控制，一般情况下不需要修改参数。pkg 参数(包名或UID，空格分隔)，放行特定应用。

## 配置参数

[参数表](https://github.com/pymumu/smartdns/blob/master/ReadMe.md#配置参数)

如果你不知道你在干什么，请保持下列参数为默认值

|参数|  功能  |默认|
|--|--|--|
|cache-file|缓存持久化文件路径|cache-file /dev/smartdns/config/smartdns.cache
|log-file|日志文件路径|log-file /dev/smartdns/config/log/smartdns.log
|audit-file|审计文件路径|audit-file /dev/smartdns/config/log/smartdns-audit.log
|ca-file|证书文件|ca-file /dev/smartdns/binary/CA/ca-certificates.crt
|ca-path|证书文件路径|ca-path /dev/smartdns/binary/CA

## 使用建议

- 启动服务器时，请确保已有互联网连接。否则会导致无法获取上游服务器的IP。
- 使用系统预留端口或测速选择 ping 时，需以 root 身份运行。
- Android 9+ 请关闭设置中的私人DNS，否则可能导致模块失效。
- 如果出现异常，使用 `smartdns -clean` 命令可使防火墙恢复至初始状态。
- 使用 VPN相关 应用时出现网络异常，请停止服务，或者尝试关闭相关应用中与 DNS相关 的处理。

- 上游优先指定 IP。至少保留一个IP地址形式的上游服务器，以解析域名形式的上游服务器。
- 同一个地址，一般没有必要配置多种协议。国内建议用 udp ，对国外优先用 tls / https 。若是移动，考虑国内用 tcp 。

## 感谢

- [SmartDNS](https://github.com/pymumu/smartdns) | pymumu
- [ClashForMagisk](https://github.com/Kr328/ClashForMagisk) | Kr328

## 捐赠

如果你觉得 SmartDNS 对你有帮助，请捐助原作者，以使项目能持续发展，更加完善。

### PayPal

[![PayPal](https://cdn.rawgit.com/twolfson/paypal-github-button/1.0.0/dist/button.svg)](https://paypal.me/PengNick/)

### Alipay

![alipay](https://raw.github.com/pymumu/smartdns/master/doc/alipay_donate.jpg)

### Wechat
  
![wechat](https://raw.github.com/pymumu/smartdns/master/doc/wechat_donate.jpg)

## 声明

### 如果您下载且安装 SmartDNS，则表示认同声明协议

- `SmartDNS` 著作权归属 Nick Peng (pymumu at gmail.com)。
- `SmartDNS` 为免费软件，用户可以非商业性地复制和使用 `SmartDNS`。
- 禁止将 `SmartDNS` 用于商业用途。
- 使用本软件的风险由用户自行承担，在适用法律允许的最大范围内，对因使用本产品所产生的损害及风险，包括但不限于直接或间接的个人损害、商业赢利的丧失、贸易中断、商业信息的丢失或任何其它经济损失，不承担任何责任。
- 本软件不会未经用户同意收集任何用户信息。
