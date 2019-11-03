# SmartDNS

![SmartDNS](https://raw.github.com/pymumu/smartdns/master/doc/smartdns-banner.png)  
SmartDNS是一个运行在本地的DNS服务器，SmartDNS接受本地客户端的DNS查询请求，从多个上游DNS服务器获取DNS查询结果，并将访问速度最快的结果返回给客户端，避免DNS污染，提高网络访问速度。
同时支持指定特定域名IP地址，并高性匹配，达到过滤广告的效果。  
与dnsmasq的all-servers不同，smartdns返回的是访问速度最快的解析结果。

## 核心代码未开源

详情请看[官方文档](https://github.com/pymumu/smartdns/blob/master/ReadMe.md)

## 使用

### 配置位于 /sdcard/smartdns/smartdns.conf

安装完成后，需要配置smartdns的上游服务器信息。具体配置参数参考`配置参数`说明。  
一般情况下，只需要增加`server [IP]:port`, `server-tcp [IP]:port`配置项，
尽可能配置多个上游DNS服务器，包括国内外的服务器。配置参数请查看`配置参数`章节。

### 脚本配置位于 `/data/adb/modules/smartdns/constant.sh`

## 配置参数

|参数|  功能  |默认值|配置值|例子|
|--|--|--|--|--|
|server-name|DNS服务器名称|操作系统主机名/smartdns|符合主机名规格的字符串|server-name smartdns
|bind|DNS监听端口号|[::]:53|可绑定多个端口<br>`IP:PORT`: 服务器IP，端口号。<br>`[-group]`: 请求时使用的DNS服务器组。<br>`[-no-rule-addr]`：跳过address规则。<br>`[-no-rule-nameserver]`：跳过Nameserver规则。<br>`[-no-rule-ipset]`：跳过Ipset规则。<br>`[no-rule-soa]`：跳过SOA(#)规则.<br>`[no-dualstack-selection]`：停用双栈测速。<br>`[-no-speed-check]`：停用测速。<br>`[-no-cache]`：停止缓存|bind :53
|bind-tcp|TCP DNS监听端口号|[::]:53|可绑定多个端口<br>`IP:PORT`: 服务器IP，端口号。<br>`[-group]`: 请求时使用的DNS服务器组。<br>`[-no-rule-addr]`：跳过address规则。<br>`[-no-rule-nameserver]`：跳过Nameserver规则。<br>`[-no-rule-ipset]`：跳过Ipset规则。<br>`[no-rule-soa]`：跳过SOA(#)规则.<br>`[no-dualstack-selection]`：停用双栈测速。<br>`[-no-speed-check]`：停用测速。<br>`[-no-cache]`：停止缓存|bind-tcp :53
|cache-size|域名结果缓存个数|512|数字|cache-size 512
|tcp-idle-time|TCP链接空闲超时时间|120|数字|tcp-idle-time 120
|rr-ttl|域名结果TTL|远程查询结果|大于0的数字|rr-ttl 600
|rr-ttl-min|允许的最小TTL值|远程查询结果|大于0的数字|rr-ttl-min 60
|rr-ttl-max|允许的最大TTL值|远程查询结果|大于0的数字|rr-ttl-max 600
|log-level|设置日志级别|error|fatal,error,warn,notice,info,debug|log-level error
|log-file|日志文件路径|/dev/smartdns_root/log/smartdns.log|路径|log-file /dev/smartdns_root/log/smartdns.log
|log-size|日志大小|128K|数字+K,M,G|log-size 128K
|log-num|日志归档个数|2|数字|log-num 2
|audit-enable|设置审计启用|no|[yes\|no]|audit-enable yes
|audit-file|审计文件路径|/dev/smartdns_root/log/smartdns-audit.log|路径|audit-file /dev/smartdns_root/log/smartdns-audit.log
|audit-size|审计大小|128K|数字+K,M,G|audit-size 128K
|audit-num|审计归档个数|2|数字|audit-num 2
|conf-file|附加配置文件|无|文件路径|conf-file /etc/smartdns/smartdns.more.conf
|server|上游UDP DNS|无|可重复<br>`[ip][:port]`：服务器IP，端口可选。<br>`[-blacklist-ip]`：blacklist-ip参数指定使用blacklist-ip配置IP过滤结果。<br>`[-whitelist-ip]`：whitelist-ip参数指定仅接受whitelist-ip中配置IP范围。<br>`[-check-edns]`：edns过滤。<br>`[-group [group] ...]`：DNS服务器所属组，比如office, foreign，和nameserver配套使用。<br>`[-exclude-default-group]`：将DNS服务器从默认组中排除| server 8.8.8.8:53 -blacklist-ip -check-edns -group g1
|server-tcp|上游TCP DNS|无|可重复<br>`[ip][:port]`：服务器IP，端口可选。<br>`[-blacklist-ip]`：blacklist-ip参数指定使用blacklist-ip配置IP过滤结果。<br>`[-whitelist-ip]`：whitelist-ip参数指定仅接受whitelist-ip中配置IP范围。<br>`[-group [group] ...]`：DNS服务器所属组，比如office, foreign，和nameserver配套使用。<br>`[-exclude-default-group]`：将DNS服务器从默认组中排除| server-tcp 8.8.8.8:53
|server-tls|上游TLS DNS|无|可重复<br>`[ip][:port]`：服务器IP，端口可选。<br>`[-spki-pin [sha256-pin]]`: TLS合法性校验SPKI值，base64编码的sha256 SPKI pin值<br>`[-host-name]`：TLS SNI名称。<br>`[-blacklist-ip]`：blacklist-ip参数指定使用blacklist-ip配置IP过滤结果。<br>`[-whitelist-ip]`：whitelist-ip参数指定仅接受whitelist-ip中配置IP范围。<br>`[-group [group] ...]`：DNS服务器所属组，比如office, foreign，和nameserver配套使用。<br>`[-exclude-default-group]`：将DNS服务器从默认组中排除| server-tls 8.8.8.8:853
|server-https|上游HTTPS DNS|无|可重复<br>`https://[host][:port]/path`：服务器IP，端口可选。<br>`[-spki-pin [sha256-pin]]`: TLS合法性校验SPKI值，base64编码的sha256 SPKI pin值<br>`[-host-name]`：TLS SNI名称<br>`[-http-host]`：http协议头主机名。<br>`[-blacklist-ip]`：blacklist-ip参数指定使用blacklist-ip配置IP过滤结果。<br>`[-whitelist-ip]`：whitelist-ip参数指定仅接受whitelist-ip中配置IP范围。<br>`[-group [group] ...]`：DNS服务器所属组，比如office, foreign，和nameserver配套使用。<br>`[-exclude-default-group]`：将DNS服务器从默认组中排除| server-https https://cloudflare-dns.com/dns-query
|address|指定域名IP地址|无|address /domain/[ip\|-\|-4\|-6\|#\|#4\|#6] <br>`-`表示忽略 <br>`#`表示返回SOA <br>`4`表示IPV4 <br>`6`表示IPV6| address /www.example.com/1.2.3.4
|nameserver|指定域名使用server组解析|无|nameserver /domain/[group\|-], `group`为组名，`-`表示忽略此规则，配套server中的`-group`参数使用| nameserver /www.example.com/office
|ipset|域名IPSET|None|ipset /domain/[ipset\|-], `-`表示忽略|ipset /www.example.com/pass
|ipset-timeout|设置IPSET超时功能启用|auto|[yes]|ipset-timeout yes
|bogus-nxdomain|假冒IP地址过滤|无|[ip/subnet]，可重复| bogus-nxdomain 1.2.3.4/16
|ignore-ip|忽略IP地址|无|[ip/subnet]，可重复| ignore-ip 1.2.3.4/16
|whitelist-ip|白名单IP地址|无|[ip/subnet]，可重复| whitelist-ip 1.2.3.4/16
|blacklist-ip|黑名单IP地址|无|[ip/subnet]，可重复| blacklist-ip 1.2.3.4/16
|force-AAAA-SOA|强制AAAA地址返回SOA|no|[yes\|no]|force-AAAA-SOA yes
|prefetch-domain|域名预先获取功能|no|[yes\|no]|prefetch-domain yes
|dualstack-ip-selection|双栈IP优选|no|[yes\|no]|dualstack-ip-selection yes
|dualstack-ip-selection-threshold|双栈IP优选阈值|30ms|毫秒|dualstack-ip-selection-threshold [0-1000]

## 感谢

- [SmartDNS](https://github.com/pymumu/smartdns) | pymumu
- [ClashForMagisk](https://github.com/Kr328/ClashForMagisk) | Kr328

## 捐赠

如果你觉得 Smartdns 对你有帮助，请捐助他们，以使项目能持续发展，更加完善。

### PayPal

[![Support via PayPal](https://cdn.rawgit.com/twolfson/paypal-github-button/1.0.0/dist/button.svg)](https://paypal.me/PengNick/)

## 声明

- `SmartDNS`著作权归属Nick Peng (pymumu at gmail.com)。
- `SmartDNS`为免费软件，用户可以非商业性地复制和使用`SmartDNS`。
- 禁止将 `SmartDNS` 用于商业用途。
- 使用本软件的风险由用户自行承担，在适用法律允许的最大范围内，对因使用本产品所产生的损害及风险，包括但不限于直接或间接的个人损害、商业赢利的丧失、贸易中断、商业信息的丢失或任何其它经济损失，不承担任何责任。
- 本软件不会未经用户同意收集任何用户信息。
